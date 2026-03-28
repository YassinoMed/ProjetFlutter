<?php

namespace App\Services\Teleconsultations;

use App\Enums\AppointmentStatus;
use App\Enums\CallSessionState;
use App\Enums\CallType;
use App\Enums\ConversationParticipantRole;
use App\Enums\TeleconsultationParticipantRole;
use App\Enums\TeleconsultationStatus;
use App\Enums\UserRole;
use App\Events\TeleconsultationUpdated;
use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Models\Teleconsultation;
use App\Models\User;
use App\Services\Appointments\AppointmentBookingService;
use App\Services\Appointments\AppointmentStateService;
use App\Services\AuditService;
use App\Services\Calls\CallSessionService;
use Illuminate\Contracts\Pagination\CursorPaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TeleconsultationService
{
    public function __construct(
        private readonly AppointmentBookingService $appointmentBookingService,
        private readonly AppointmentStateService $appointmentStateService,
        private readonly CallSessionService $callSessionService,
        private readonly TurnCredentialsService $turnCredentialsService,
        private readonly TeleconsultationEventLogger $eventLogger,
        private readonly TeleconsultationStateSynchronizer $stateSynchronizer,
        private readonly AuditService $auditService,
    ) {}

    public function listForUser(
        User $actor,
        array $filters = [],
        ?string $actingDoctorUserId = null,
        int $perPage = 20,
    ): CursorPaginator {
        $query = Teleconsultation::query()
            ->with(['participants', 'currentCallSession.participants'])
            ->when(! empty($filters['status']), fn (Builder $builder) => $builder->where('status', $filters['status']))
            ->when(! empty($filters['appointment_id']), fn (Builder $builder) => $builder->where('appointment_id', $filters['appointment_id']))
            ->when(! empty($filters['doctor_user_id']), fn (Builder $builder) => $builder->where('doctor_user_id', $filters['doctor_user_id']))
            ->when(! empty($filters['patient_user_id']), fn (Builder $builder) => $builder->where('patient_user_id', $filters['patient_user_id']))
            ->when(! empty($filters['from_utc']), fn (Builder $builder) => $builder->where('scheduled_starts_at_utc', '>=', Carbon::parse($filters['from_utc'], 'UTC')))
            ->when(! empty($filters['to_utc']), fn (Builder $builder) => $builder->where('scheduled_starts_at_utc', '<=', Carbon::parse($filters['to_utc'], 'UTC')));

        if (($actor->role?->value ?? $actor->role) === UserRole::ADMIN->value) {
            return $query
                ->orderByDesc('scheduled_starts_at_utc')
                ->cursorPaginate(min(max($perPage, 1), 50));
        }

        if (($actor->role?->value ?? $actor->role) === UserRole::SECRETARY->value && $actingDoctorUserId !== null) {
            $query->where('doctor_user_id', $actingDoctorUserId);

            return $query
                ->orderByDesc('scheduled_starts_at_utc')
                ->cursorPaginate(min(max($perPage, 1), 50));
        }

        return $query
            ->where(function (Builder $builder) use ($actor): void {
                $builder
                    ->where('patient_user_id', $actor->id)
                    ->orWhere('doctor_user_id', $actor->id)
                    ->orWhereHas('participants', function (Builder $participantQuery) use ($actor): void {
                        $participantQuery
                            ->where('user_id', $actor->id)
                            ->whereNull('access_revoked_at_utc');
                    });
            })
            ->orderByDesc('scheduled_starts_at_utc')
            ->cursorPaginate(min(max($perPage, 1), 50));
    }

    public function create(
        User $actor,
        array $payload,
        ?string $actingDoctorUserId = null,
        ?string $delegationId = null,
        ?Request $request = null,
    ): Teleconsultation {
        $appointment = $this->resolveOrCreateAppointment($actor, $payload, $actingDoctorUserId);

        $existing = Teleconsultation::query()
            ->with(['participants', 'currentCallSession.participants'])
            ->where('appointment_id', $appointment->id)
            ->first();

        if ($existing !== null) {
            return $existing;
        }

        $callType = $payload['call_type'] ?? CallType::VIDEO->value;

        $teleconsultation = DB::transaction(function () use ($actor, $appointment, $callType): Teleconsultation {
            $conversation = $this->createOrFindConversationForAppointment($appointment, $actor);

            $teleconsultation = Teleconsultation::query()->create([
                'appointment_id' => $appointment->id,
                'conversation_id' => $conversation->id,
                'patient_user_id' => $appointment->patient_user_id,
                'doctor_user_id' => $appointment->doctor_user_id,
                'created_by_user_id' => $actor->id,
                'call_type' => $callType,
                'status' => TeleconsultationStatus::SCHEDULED->value,
                'scheduled_starts_at_utc' => $appointment->starts_at_utc,
                'scheduled_ends_at_utc' => $appointment->ends_at_utc,
                'server_metadata' => [
                    'created_via' => 'teleconsultations.api',
                ],
            ]);

            $teleconsultation->participants()->createMany([
                [
                    'user_id' => $appointment->patient_user_id,
                    'role' => TeleconsultationParticipantRole::PATIENT->value,
                    'invited_at_utc' => now('UTC'),
                    'can_publish_audio' => true,
                    'can_publish_video' => true,
                ],
                [
                    'user_id' => $appointment->doctor_user_id,
                    'role' => TeleconsultationParticipantRole::DOCTOR->value,
                    'invited_at_utc' => now('UTC'),
                    'can_publish_audio' => true,
                    'can_publish_video' => true,
                ],
            ]);

            $teleconsultation = $teleconsultation->fresh(['participants', 'currentCallSession.participants']);
            $this->eventLogger->record($teleconsultation, 'teleconsultation.scheduled', $actor, payload: [
                'appointment_id' => $appointment->id,
                'call_type' => $callType,
            ]);

            DB::afterCommit(fn () => event(new TeleconsultationUpdated($teleconsultation)));

            return $teleconsultation;
        });

        $this->auditService->log(
            $actor,
            'teleconsultation.created',
            $teleconsultation,
            [
                'appointment_id' => $teleconsultation->appointment_id,
                'call_type' => $teleconsultation->call_type?->value ?? $teleconsultation->call_type,
            ],
            $actingDoctorUserId,
            $delegationId,
            $request,
        );

        return $teleconsultation;
    }

    public function start(
        Teleconsultation $teleconsultation,
        User $actor,
        array $payload = [],
        ?string $actingDoctorUserId = null,
        ?string $delegationId = null,
        ?Request $request = null,
    ): Teleconsultation {
        $teleconsultation = $this->loadGraph($teleconsultation);
        $teleconsultation = $this->syncStatus($teleconsultation);

        if (! in_array($teleconsultation->status?->value ?? $teleconsultation->status, [
            TeleconsultationStatus::SCHEDULED->value,
            TeleconsultationStatus::RINGING->value,
        ], true)) {
            throw ValidationException::withMessages([
                'teleconsultation' => ['The teleconsultation cannot be started in its current state.'],
            ]);
        }

        if ($teleconsultation->appointment !== null
            && $teleconsultation->appointment->status === AppointmentStatus::REQUESTED) {
            $this->appointmentStateService->transition(
                appointment: $teleconsultation->appointment,
                to: AppointmentStatus::CONFIRMED,
                actorUserId: $actor->id,
            );
        }

        if ($teleconsultation->currentCallSession !== null && in_array(
            $teleconsultation->currentCallSession->current_state?->value ?? $teleconsultation->currentCallSession->current_state,
            [CallSessionState::RINGING->value, CallSessionState::ACCEPTED->value],
            true,
        )) {
            return $this->loadGraph($teleconsultation);
        }

        $callSession = $this->callSessionService->initiate($actor, [
            'conversation_id' => $teleconsultation->conversation_id,
            'consultation_id' => $teleconsultation->appointment_id,
            'call_type' => $payload['call_type'] ?? ($teleconsultation->call_type?->value ?? $teleconsultation->call_type),
            'server_metadata' => array_filter([
                'teleconsultation_id' => $teleconsultation->id,
                'session_reference' => $teleconsultation->session_reference,
            ]),
        ]);

        $teleconsultation->forceFill([
            'call_type' => $callSession->call_type?->value ?? $callSession->call_type,
            'current_call_session_id' => $callSession->id,
            'conversation_id' => $callSession->conversation_id,
        ])->save();

        $teleconsultation = $this->syncStatus($teleconsultation->fresh());

        $this->eventLogger->record($teleconsultation, 'teleconsultation.started', $actor, callSession: $callSession, payload: [
            'call_type' => $callSession->call_type?->value ?? $callSession->call_type,
        ]);

        $this->auditService->log(
            $actor,
            'teleconsultation.started',
            $teleconsultation,
            ['call_session_id' => $callSession->id],
            $actingDoctorUserId,
            $delegationId,
            $request,
        );

        return $this->loadGraph($teleconsultation);
    }

    public function join(
        Teleconsultation $teleconsultation,
        User $actor,
        array $payload = [],
        ?string $actingDoctorUserId = null,
        ?string $delegationId = null,
        ?Request $request = null,
    ): array {
        $teleconsultation = $this->loadGraph($teleconsultation);
        $teleconsultation = $this->syncStatus($teleconsultation);

        if ($teleconsultation->current_call_session_id === null) {
            if ($teleconsultation->doctor_user_id === $actor->id) {
                $teleconsultation = $this->start($teleconsultation, $actor, [], $actingDoctorUserId, $delegationId, $request);
            } else {
                throw ValidationException::withMessages([
                    'teleconsultation' => ['The teleconsultation has not been started yet.'],
                ]);
            }
        }

        /** @var CallSession $callSession */
        $callSession = CallSession::query()
            ->with('participants')
            ->findOrFail($teleconsultation->current_call_session_id);

        $callState = $callSession->current_state?->value ?? $callSession->current_state;

        if ($callState === CallSessionState::RINGING->value && $callSession->initiated_by_user_id !== $actor->id) {
            $callSession = $this->callSessionService->accept($callSession, $actor);
        } elseif ($callState === CallSessionState::ACCEPTED->value) {
            $callSession->participants()
                ->where('user_id', $actor->id)
                ->update([
                    'joined_at_utc' => DB::raw('COALESCE(joined_at_utc, CURRENT_TIMESTAMP)'),
                    'last_seen_at_utc' => now('UTC'),
                ]);
        } elseif (! in_array($callState, [CallSessionState::RINGING->value, CallSessionState::ACCEPTED->value], true)) {
            $teleconsultation = $this->syncStatus($teleconsultation);

            throw ValidationException::withMessages([
                'teleconsultation' => ['The teleconsultation is not joinable anymore.'],
            ]);
        }

        $teleconsultation->participants()
            ->where('user_id', $actor->id)
            ->update([
                'joined_at_utc' => DB::raw('COALESCE(joined_at_utc, CURRENT_TIMESTAMP)'),
                'last_seen_at_utc' => now('UTC'),
            ]);

        $teleconsultation = $this->syncStatus($teleconsultation->fresh());

        $this->eventLogger->record($teleconsultation, 'teleconsultation.joined', $actor, callSession: $callSession, payload: [
            'device_label' => $payload['device_label'] ?? null,
            'camera_enabled' => $payload['camera_enabled'] ?? null,
            'microphone_enabled' => $payload['microphone_enabled'] ?? null,
        ]);

        $this->auditService->log(
            $actor,
            'teleconsultation.joined',
            $teleconsultation,
            ['call_session_id' => $callSession->id],
            $actingDoctorUserId,
            $delegationId,
            $request,
        );

        $otherParticipant = $teleconsultation->participants->firstWhere('user_id', '!=', $actor->id);

        return [
            'teleconsultation' => $this->loadGraph($teleconsultation),
            'call_session' => $callSession->fresh('participants'),
            'rtc_configuration' => $this->turnCredentialsService->forUser($actor),
            'self_user_id' => $actor->id,
            'remote_user_id' => $otherParticipant?->user_id,
            'chat' => [
                'conversation_id' => $teleconsultation->conversation_id,
            ],
        ];
    }

    public function cancel(
        Teleconsultation $teleconsultation,
        User $actor,
        array $payload = [],
        ?string $actingDoctorUserId = null,
        ?string $delegationId = null,
        ?Request $request = null,
    ): Teleconsultation {
        $teleconsultation = $this->loadGraph($teleconsultation);
        $teleconsultation = $this->syncStatus($teleconsultation);

        $callSession = $teleconsultation->currentCallSession;
        $reason = $payload['reason'] ?? 'cancelled';

        if ($callSession !== null) {
            $state = $callSession->current_state?->value ?? $callSession->current_state;

            if ($state === CallSessionState::RINGING->value) {
                if ($callSession->initiated_by_user_id === $actor->id) {
                    $this->callSessionService->cancel($callSession, $actor);
                } else {
                    $this->callSessionService->reject($callSession, $actor);
                }
            } elseif ($state === CallSessionState::ACCEPTED->value) {
                throw ValidationException::withMessages([
                    'teleconsultation' => ['Use the end endpoint to close an active teleconsultation.'],
                ]);
            }
        } else {
            $teleconsultation->forceFill([
                'status' => TeleconsultationStatus::CANCELLED->value,
                'ended_at_utc' => now('UTC'),
                'cancellation_reason' => $reason,
            ])->save();

            event(new TeleconsultationUpdated($teleconsultation->fresh(['participants', 'currentCallSession'])));
        }

        $this->cancelAppointmentIfPossible($teleconsultation, $actor, $reason);

        $teleconsultation = $this->loadGraph($teleconsultation->fresh());
        $this->eventLogger->record($teleconsultation, 'teleconsultation.cancelled', $actor, payload: ['reason' => $reason]);

        $this->auditService->log(
            $actor,
            'teleconsultation.cancelled',
            $teleconsultation,
            ['reason' => $reason],
            $actingDoctorUserId,
            $delegationId,
            $request,
        );

        return $teleconsultation;
    }

    public function end(
        Teleconsultation $teleconsultation,
        User $actor,
        array $payload = [],
        ?string $actingDoctorUserId = null,
        ?string $delegationId = null,
        ?Request $request = null,
    ): Teleconsultation {
        $teleconsultation = $this->loadGraph($teleconsultation);
        $teleconsultation = $this->syncStatus($teleconsultation);

        if ($teleconsultation->currentCallSession === null) {
            throw ValidationException::withMessages([
                'teleconsultation' => ['No active call session found for this teleconsultation.'],
            ]);
        }

        $callSession = $this->callSessionService->end($teleconsultation->currentCallSession, $actor);
        $teleconsultation = $this->syncStatus($teleconsultation->fresh());

        $this->completeAppointmentIfPossible($teleconsultation, $actor);
        $this->eventLogger->record($teleconsultation, 'teleconsultation.completed', $actor, callSession: $callSession, payload: [
            'reason' => $payload['reason'] ?? null,
            'connection_quality' => $payload['connection_quality'] ?? null,
        ]);

        $this->auditService->log(
            $actor,
            'teleconsultation.completed',
            $teleconsultation,
            ['call_session_id' => $callSession->id],
            $actingDoctorUserId,
            $delegationId,
            $request,
        );

        return $this->loadGraph($teleconsultation);
    }

    public function relayOffer(Teleconsultation $teleconsultation, User $actor, array $payload): void
    {
        $callSession = $this->resolveJoinableCallSession($teleconsultation);
        $this->callSessionService->relayOffer($callSession, $actor, $payload);
    }

    public function relayAnswer(Teleconsultation $teleconsultation, User $actor, array $payload): void
    {
        $callSession = $this->resolveJoinableCallSession($teleconsultation);
        $this->callSessionService->relayAnswer($callSession, $actor, $payload);
    }

    public function relayIceCandidate(Teleconsultation $teleconsultation, User $actor, array $payload): void
    {
        $callSession = $this->resolveJoinableCallSession($teleconsultation);
        $this->callSessionService->relayIceCandidate($callSession, $actor, $payload);
    }

    public function listEvents(Teleconsultation $teleconsultation, int $limit = 50): array
    {
        return $teleconsultation->callEvents()
            ->latest('occurred_at_utc')
            ->limit(min(max($limit, 1), 100))
            ->get()
            ->all();
    }

    public function syncStatus(Teleconsultation $teleconsultation): Teleconsultation
    {
        $teleconsultation = $teleconsultation->relationLoaded('currentCallSession')
            ? $teleconsultation
            : $teleconsultation->load('currentCallSession');

        if ($teleconsultation->currentCallSession !== null) {
            $synced = $this->stateSynchronizer->syncFromCallSession($teleconsultation->currentCallSession);

            if ($synced !== null) {
                return $this->loadGraph($synced);
            }
        }

        return $this->loadGraph($teleconsultation);
    }

    private function resolveOrCreateAppointment(User $actor, array $payload, ?string $actingDoctorUserId): Appointment
    {
        if (! empty($payload['appointment_id'])) {
            $appointment = Appointment::query()->findOrFail($payload['appointment_id']);
            $this->assertActorCanAccessAppointment($actor, $appointment, $actingDoctorUserId);

            return $appointment;
        }

        $patientUserId = $payload['patient_user_id'] ?? null;
        $doctorUserId = $payload['doctor_user_id'] ?? null;

        $role = $actor->role?->value ?? $actor->role;

        if ($role === UserRole::PATIENT->value) {
            $patientUserId = $actor->id;
        }

        if ($role === UserRole::DOCTOR->value) {
            $doctorUserId = $actor->id;
        }

        if ($role === UserRole::SECRETARY->value) {
            if ($actingDoctorUserId === null) {
                throw ValidationException::withMessages([
                    'doctor_user_id' => ['Secretary teleconsultation creation requires an active doctor context.'],
                ]);
            }

            $doctorUserId = $actingDoctorUserId;
        }

        if ($patientUserId === null || $doctorUserId === null) {
            throw ValidationException::withMessages([
                'teleconsultation' => ['Missing patient or doctor information to create the teleconsultation.'],
            ]);
        }

        return $this->appointmentBookingService->createRequested(
            patientUserId: $patientUserId,
            doctorUserId: $doctorUserId,
            startsAtUtc: Carbon::parse($payload['scheduled_starts_at_utc'], 'UTC'),
            endsAtUtc: Carbon::parse($payload['scheduled_ends_at_utc'], 'UTC'),
            metadataEncrypted: array_filter([
                'consultation_type' => 'TELECONSULTATION',
                'call_type' => $payload['call_type'] ?? CallType::VIDEO->value,
                'origin' => 'teleconsultations.api',
            ]),
        );
    }

    private function createOrFindConversationForAppointment(Appointment $appointment, User $actor): Conversation
    {
        $conversation = Conversation::query()
            ->with('participants')
            ->where('consultation_id', $appointment->id)
            ->first();

        if ($conversation !== null) {
            return $conversation;
        }

        return DB::transaction(function () use ($appointment, $actor): Conversation {
            $conversation = Conversation::query()->create([
                'consultation_id' => $appointment->id,
                'initiated_by_user_id' => $actor->id,
                'type' => 'DIRECT_MEDICAL',
                'server_metadata' => [
                    'created_via' => 'teleconsultations.api',
                ],
            ]);

            $conversation->participants()->createMany([
                [
                    'user_id' => $appointment->patient_user_id,
                    'role' => ConversationParticipantRole::PATIENT->value,
                    'is_active' => true,
                    'joined_at_utc' => now('UTC'),
                    'last_seen_at_utc' => now('UTC'),
                ],
                [
                    'user_id' => $appointment->doctor_user_id,
                    'role' => ConversationParticipantRole::DOCTOR->value,
                    'is_active' => true,
                    'joined_at_utc' => now('UTC'),
                    'last_seen_at_utc' => now('UTC'),
                ],
            ]);

            return $conversation->load('participants');
        });
    }

    private function cancelAppointmentIfPossible(Teleconsultation $teleconsultation, User $actor, string $reason): void
    {
        $appointment = $teleconsultation->appointment()->first();

        if ($appointment === null || ! in_array($appointment->status, [
            AppointmentStatus::REQUESTED,
            AppointmentStatus::CONFIRMED,
        ], true)) {
            return;
        }

        $this->appointmentStateService->transition(
            appointment: $appointment,
            to: AppointmentStatus::CANCELLED,
            actorUserId: $actor->id,
            cancelReason: $reason,
        );
    }

    private function completeAppointmentIfPossible(Teleconsultation $teleconsultation, User $actor): void
    {
        $appointment = $teleconsultation->appointment()->first();

        if ($appointment === null || $appointment->status !== AppointmentStatus::CONFIRMED) {
            return;
        }

        $this->appointmentStateService->transition(
            appointment: $appointment,
            to: AppointmentStatus::COMPLETED,
            actorUserId: $actor->id,
        );
    }

    private function assertActorCanAccessAppointment(User $actor, Appointment $appointment, ?string $actingDoctorUserId): void
    {
        $role = $actor->role?->value ?? $actor->role;

        if ($role === UserRole::ADMIN->value) {
            return;
        }

        if ($role === UserRole::SECRETARY->value) {
            if ($actingDoctorUserId === null || $appointment->doctor_user_id !== $actingDoctorUserId) {
                throw ValidationException::withMessages([
                    'appointment_id' => ['The selected appointment is outside the current doctor delegation context.'],
                ]);
            }

            return;
        }

        if (! in_array($actor->id, [$appointment->patient_user_id, $appointment->doctor_user_id], true)) {
            throw ValidationException::withMessages([
                'appointment_id' => ['You are not allowed to create a teleconsultation for this appointment.'],
            ]);
        }
    }

    private function resolveJoinableCallSession(Teleconsultation $teleconsultation): CallSession
    {
        $teleconsultation = $this->syncStatus($teleconsultation);

        if ($teleconsultation->currentCallSession === null) {
            throw ValidationException::withMessages([
                'teleconsultation' => ['No active call session exists for this teleconsultation.'],
            ]);
        }

        return $teleconsultation->currentCallSession;
    }

    private function loadGraph(Teleconsultation $teleconsultation): Teleconsultation
    {
        return $teleconsultation->fresh([
            'appointment',
            'participants',
            'currentCallSession.participants',
        ]) ?? $teleconsultation->loadMissing([
            'appointment',
            'participants',
            'currentCallSession.participants',
        ]);
    }
}
