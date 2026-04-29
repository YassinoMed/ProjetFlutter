<?php

namespace App\Services\Calls;

use App\Enums\CallParticipantRole;
use App\Enums\CallSessionState;
use App\Events\CallSessionAccepted;
use App\Events\CallSessionEnded;
use App\Events\CallSessionRejected;
use App\Events\CallSessionRinging;
use App\Events\CallSessionTimedOut;
use App\Events\WebRtcAnswerRelayed;
use App\Events\WebRtcIceCandidateRelayed;
use App\Events\WebRtcOfferRelayed;
use App\Jobs\ExpireCallSessionJob;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Models\User;
use App\Notifications\IncomingCallSessionNotification;
use App\Services\AuditService;
use App\Services\Conversations\ConversationService;
use App\Services\Teleconsultations\TeleconsultationEventLogger;
use App\Services\Teleconsultations\TeleconsultationStateSynchronizer;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class CallSessionService
{
    public function __construct(
        private readonly ConversationService $conversationService,
        private readonly AuditService $auditService,
        private readonly TeleconsultationEventLogger $teleconsultationEventLogger,
        private readonly TeleconsultationStateSynchronizer $teleconsultationStateSynchronizer,
    ) {}

    public function initiate(User $actor, array $payload): CallSession
    {
        /** @var Conversation $conversation */
        $conversation = Conversation::query()
            ->with('participants.user')
            ->findOrFail($payload['conversation_id']);

        $this->conversationService->assertParticipant($conversation, $actor);

        $hasActiveCall = CallSession::query()
            ->where(function ($query) use ($conversation, $payload): void {
                $query->where('conversation_id', $conversation->id);

                if (! empty($payload['consultation_id'])) {
                    $query->orWhere('consultation_id', $payload['consultation_id']);
                }
            })
            ->whereIn('current_state', [
                CallSessionState::INITIATED->value,
                CallSessionState::RINGING->value,
                CallSessionState::ACCEPTED->value,
            ])
            ->exists();

        if ($hasActiveCall) {
            throw new ConflictHttpException('An active call already exists for this consultation.');
        }

        if ($conversation->participants->where('user_id', '!=', $actor->id)->where('is_active', true)->isEmpty()) {
            throw new ConflictHttpException('No reachable call participant found.');
        }

        return DB::transaction(function () use ($conversation, $actor, $payload): CallSession {
            $call = CallSession::query()->create([
                'consultation_id' => $payload['consultation_id'] ?? $conversation->consultation_id,
                'conversation_id' => $conversation->id,
                'initiated_by_user_id' => $actor->id,
                'call_type' => $payload['call_type'],
                'current_state' => CallSessionState::RINGING->value,
                'started_ringing_at_utc' => now('UTC'),
                'expires_at_utc' => now('UTC')->addSeconds(config('mediconnect.call_ring_timeout_seconds', 45)),
                'server_metadata' => $payload['server_metadata'] ?? null,
            ]);

            foreach ($conversation->participants as $participant) {
                $call->participants()->create([
                    'user_id' => $participant->user_id,
                    'role' => $participant->user_id === $actor->id
                        ? CallParticipantRole::CALLER->value
                        : CallParticipantRole::CALLEE->value,
                    'joined_at_utc' => $participant->user_id === $actor->id ? now('UTC') : null,
                ]);
            }

            $this->auditService->log($actor, 'call.initiated', $call, [
                'conversation_id' => $conversation->id,
                'call_type' => $call->call_type?->value ?? $call->call_type,
            ]);

            $this->teleconsultationStateSynchronizer->syncFromCallSession($call);
            $this->teleconsultationEventLogger->recordForCallSession(
                $call,
                'webrtc.ringing',
                $actor,
                payload: [
                    'conversation_id' => $conversation->id,
                    'call_type' => $call->call_type?->value ?? $call->call_type,
                ],
                direction: 'server_to_client',
            );

            DB::afterCommit(function () use ($call, $conversation, $actor): void {
                $call = $call->load('participants');

                event(new CallSessionRinging($call));

                $conversation->participants
                    ->where('user_id', '!=', $actor->id)
                    ->each(function ($participant) use ($call, $actor): void {
                        $participant->user?->notify(new IncomingCallSessionNotification($call, $actor));
                    });

                ExpireCallSessionJob::dispatch($call->id)->delay($call->expires_at_utc);
            });

            return $call->load('participants');
        });
    }

    public function accept(CallSession $call, User $user): CallSession
    {
        $call = $this->refreshIfExpired($call);
        $this->assertParticipant($call, $user);

        if ($call->initiated_by_user_id === $user->id) {
            throw new ConflictHttpException('The caller cannot accept their own call.');
        }

        $this->assertInState($call, [CallSessionState::INITIATED, CallSessionState::RINGING]);

        return DB::transaction(function () use ($call, $user): CallSession {
            $call->forceFill([
                'current_state' => CallSessionState::ACCEPTED->value,
                'accepted_at_utc' => now('UTC'),
            ])->save();

            $call->participants()
                ->where('user_id', $user->id)
                ->update([
                    'joined_at_utc' => now('UTC'),
                    'last_seen_at_utc' => now('UTC'),
                ]);

            $this->auditService->log($user, 'call.accepted', $call);
            $this->teleconsultationStateSynchronizer->syncFromCallSession($call);
            $this->teleconsultationEventLogger->recordForCallSession(
                $call,
                'webrtc.accepted',
                $user,
                direction: 'server_to_client',
            );

            DB::afterCommit(fn () => event(new CallSessionAccepted($call->fresh('participants'))));

            return $call->fresh('participants');
        });
    }

    public function reject(CallSession $call, User $user): CallSession
    {
        $call = $this->refreshIfExpired($call);
        $this->assertParticipant($call, $user);

        if ($call->initiated_by_user_id === $user->id) {
            throw new ConflictHttpException('The caller cannot reject their own call.');
        }

        $this->assertInState($call, [CallSessionState::INITIATED, CallSessionState::RINGING]);

        return $this->finalize($call, $user, CallSessionState::REJECTED, 'rejected');
    }

    public function cancel(CallSession $call, User $user): CallSession
    {
        $call = $this->refreshIfExpired($call);
        $this->assertParticipant($call, $user);

        if ($call->initiated_by_user_id !== $user->id) {
            throw new AuthorizationException('Only the caller can cancel the ringing call.');
        }

        $this->assertInState($call, [CallSessionState::INITIATED, CallSessionState::RINGING]);

        return $this->finalize($call, $user, CallSessionState::CANCELLED, 'cancelled');
    }

    public function cancelForTeleconsultation(CallSession $call, User $user): CallSession
    {
        $call = $this->refreshIfExpired($call);
        $this->assertParticipant($call, $user);
        $this->assertInState($call, [CallSessionState::INITIATED, CallSessionState::RINGING]);

        return $this->finalize($call, $user, CallSessionState::CANCELLED, 'cancelled');
    }

    public function end(CallSession $call, User $user): CallSession
    {
        $call = $call->fresh('participants') ?? $call;
        $this->assertParticipant($call, $user);
        $this->assertInState($call, [CallSessionState::ACCEPTED]);

        return $this->finalize($call, $user, CallSessionState::ENDED, 'ended');
    }

    public function timeoutIfExpired(string $callSessionId): ?CallSession
    {
        /** @var CallSession|null $call */
        $call = CallSession::query()->find($callSessionId);

        if ($call === null) {
            return null;
        }

        if (! in_array($call->current_state?->value ?? $call->current_state, [
            CallSessionState::INITIATED->value,
            CallSessionState::RINGING->value,
        ], true)) {
            return $call;
        }

        if ($call->expires_at_utc->isFuture()) {
            return $call;
        }

        return DB::transaction(function () use ($call): CallSession {
            $call->forceFill([
                'current_state' => CallSessionState::TIMEOUT->value,
                'ended_at_utc' => now('UTC'),
                'end_reason' => 'timeout',
            ])->save();

            $this->auditService->log(null, 'call.timeout', $call);
            $this->teleconsultationStateSynchronizer->syncFromCallSession($call);
            $this->teleconsultationEventLogger->recordForCallSession(
                $call,
                'webrtc.timeout',
                payload: ['reason' => 'timeout'],
                direction: 'server_to_client',
            );

            DB::afterCommit(fn () => event(new CallSessionTimedOut($call->fresh('participants'))));

            return $call->fresh('participants');
        });
    }

    public function relayOffer(CallSession $call, User $user, array $payload): void
    {
        $call = $this->refreshIfExpired($call);
        $this->assertInState($call, [CallSessionState::RINGING, CallSessionState::ACCEPTED]);
        $targetUserId = $this->resolveTargetUserId($call, $user, $payload['target_user_id']);

        $this->auditService->log($user, 'webrtc.offer.relayed', $call, [
            'target_user_id' => $targetUserId,
        ]);

        $this->teleconsultationEventLogger->recordForCallSession(
            $call,
            'webrtc.offer',
            $user,
            $targetUserId,
            payload: [
                'sdp' => $payload['sdp'],
            ],
            direction: 'client_to_client',
        );

        event(new WebRtcOfferRelayed(
            $call->id,
            $call->conversation_id,
            $user->id,
            $targetUserId,
            $payload['sdp'],
            now('UTC')->toISOString(),
        ));
    }

    public function relayAnswer(CallSession $call, User $user, array $payload): void
    {
        $call = $this->refreshIfExpired($call);
        $this->assertInState($call, [CallSessionState::RINGING, CallSessionState::ACCEPTED]);
        $targetUserId = $this->resolveTargetUserId($call, $user, $payload['target_user_id']);

        $this->auditService->log($user, 'webrtc.answer.relayed', $call, [
            'target_user_id' => $targetUserId,
        ]);

        $this->teleconsultationEventLogger->recordForCallSession(
            $call,
            'webrtc.answer',
            $user,
            $targetUserId,
            payload: [
                'sdp' => $payload['sdp'],
            ],
            direction: 'client_to_client',
        );

        event(new WebRtcAnswerRelayed(
            $call->id,
            $call->conversation_id,
            $user->id,
            $targetUserId,
            $payload['sdp'],
            now('UTC')->toISOString(),
        ));
    }

    public function relayIceCandidate(CallSession $call, User $user, array $payload): void
    {
        $call = $this->refreshIfExpired($call);
        $this->assertInState($call, [CallSessionState::RINGING, CallSessionState::ACCEPTED]);
        $targetUserId = $this->resolveTargetUserId($call, $user, $payload['target_user_id']);

        $this->auditService->log($user, 'webrtc.ice_candidate.relayed', $call, [
            'target_user_id' => $targetUserId,
        ]);

        $this->teleconsultationEventLogger->recordForCallSession(
            $call,
            'webrtc.ice_candidate',
            $user,
            $targetUserId,
            payload: [
                'candidate' => $payload['candidate'],
            ],
            direction: 'client_to_client',
        );

        event(new WebRtcIceCandidateRelayed(
            $call->id,
            $call->conversation_id,
            $user->id,
            $targetUserId,
            $payload['candidate'],
            now('UTC')->toISOString(),
        ));
    }

    private function finalize(CallSession $call, User $user, CallSessionState $state, string $reason): CallSession
    {
        return DB::transaction(function () use ($call, $user, $state, $reason): CallSession {
            $call->forceFill([
                'current_state' => $state->value,
                'ended_at_utc' => now('UTC'),
                'ended_by_user_id' => $user->id,
                'end_reason' => $reason,
            ])->save();

            $call->participants()
                ->where('user_id', $user->id)
                ->update([
                    'left_at_utc' => now('UTC'),
                    'last_seen_at_utc' => now('UTC'),
                ]);

            $this->auditService->log($user, 'call.'.$reason, $call);
            $this->teleconsultationStateSynchronizer->syncFromCallSession($call);
            $this->teleconsultationEventLogger->recordForCallSession(
                $call,
                $state === CallSessionState::REJECTED ? 'webrtc.rejected' : 'webrtc.ended',
                $user,
                payload: ['reason' => $reason],
                direction: 'server_to_client',
            );

            DB::afterCommit(function () use ($call, $state): void {
                $call = $call->fresh('participants');

                if ($state === CallSessionState::REJECTED) {
                    event(new CallSessionRejected($call));

                    return;
                }

                event(new CallSessionEnded($call));
            });

            return $call->fresh('participants');
        });
    }

    private function resolveTargetUserId(CallSession $call, User $user, string $targetUserId): string
    {
        $this->assertParticipant($call, $user);

        $exists = $call->participants()
            ->where('user_id', $targetUserId)
            ->exists();

        if (! $exists || $targetUserId === $user->id) {
            throw ValidationException::withMessages([
                'target_user_id' => ['Invalid WebRTC signaling target user.'],
            ]);
        }

        return $targetUserId;
    }

    private function assertParticipant(CallSession $call, User $user): void
    {
        $isParticipant = $call->participants()
            ->where('user_id', $user->id)
            ->exists();

        if (! $isParticipant) {
            throw new AuthorizationException('You are not allowed to access this call session.');
        }
    }

    /**
     * @param  array<int, CallSessionState>  $states
     */
    private function assertInState(CallSession $call, array $states): void
    {
        $allowed = array_map(static fn (CallSessionState $state) => $state->value, $states);

        if (! in_array($call->current_state?->value ?? $call->current_state, $allowed, true)) {
            throw new ConflictHttpException('The call session is not in a valid state for this operation.');
        }
    }

    private function refreshIfExpired(CallSession $call): CallSession
    {
        $call = $call->fresh('participants') ?? $call;
        $state = $call->current_state?->value ?? $call->current_state;

        if (! in_array($state, [
            CallSessionState::INITIATED->value,
            CallSessionState::RINGING->value,
        ], true)) {
            return $call;
        }

        if ($call->expires_at_utc === null || $call->expires_at_utc->isFuture()) {
            return $call;
        }

        return $this->timeoutIfExpired($call->id)?->load('participants') ?? $call;
    }
}
