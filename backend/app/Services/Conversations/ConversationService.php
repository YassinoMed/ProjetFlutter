<?php

namespace App\Services\Conversations;

use App\Enums\ConversationParticipantRole;
use App\Enums\UserRole;
use App\Models\Appointment;
use App\Models\Conversation;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Contracts\Pagination\CursorPaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ConversationService
{
    public function listForUser(User $user, int $perPage = 20): CursorPaginator
    {
        return Conversation::query()
            ->whereHas('participants', function (Builder $query) use ($user): void {
                $query->where('user_id', $user->id)->where('is_active', true);
            })
            ->with(['participants'])
            ->orderByDesc('last_message_at_utc')
            ->cursorPaginate($perPage);
    }

    public function createOrFind(User $actor, array $payload): Conversation
    {
        $peer = User::query()->findOrFail($payload['participant_user_id']);
        $consultation = $this->findAuthorizedConsultationBetween($actor, $peer, $payload['consultation_id'] ?? null);

        $existing = Conversation::query()
            ->with('participants')
            ->where('consultation_id', $consultation->id)
            ->first();

        if ($existing !== null) {
            $this->touchPresence($existing, $actor);

            return $existing;
        }

        return DB::transaction(function () use ($actor, $peer, $consultation): Conversation {
            $conversation = Conversation::query()->create([
                'consultation_id' => $consultation->id,
                'initiated_by_user_id' => $actor->id,
                'type' => 'DIRECT_MEDICAL',
                'server_metadata' => [
                    'created_via' => 'api',
                ],
            ]);

            $participants = [$actor, $peer];

            foreach ($participants as $participant) {
                $conversation->participants()->create([
                    'user_id' => $participant->id,
                    'role' => $this->roleFor($participant)->value,
                    'is_active' => true,
                    'joined_at_utc' => now('UTC'),
                    'last_seen_at_utc' => now('UTC'),
                ]);
            }

            return $conversation->load('participants');
        });
    }

    public function touchPresence(Conversation $conversation, User $user): void
    {
        $conversation->participants()
            ->where('user_id', $user->id)
            ->update(['last_seen_at_utc' => now('UTC')]);
    }

    public function presenceSummary(Conversation $conversation): array
    {
        $freshnessThreshold = now('UTC')->subSeconds(config('mediconnect.presence_freshness_seconds', 90));

        return $conversation->participants()
            ->with('user')
            ->get()
            ->map(function ($participant) use ($freshnessThreshold): array {
                return [
                    'user_id' => $participant->user_id,
                    'role' => $participant->role?->value ?? $participant->role,
                    'is_online' => $participant->last_seen_at_utc !== null && $participant->last_seen_at_utc->gte($freshnessThreshold),
                    'last_seen_at_utc' => optional($participant->last_seen_at_utc)?->setTimezone('UTC')?->toISOString(),
                ];
            })
            ->all();
    }

    public function findAuthorizedConsultationBetween(User $actor, User $peer, ?string $consultationId = null): Appointment
    {
        if ($actor->id === $peer->id) {
            throw ValidationException::withMessages([
                'participant_user_id' => ['A conversation cannot be created with the same user.'],
            ]);
        }

        $roles = [$actor->role?->value ?? $actor->role, $peer->role?->value ?? $peer->role];

        if (! in_array(UserRole::PATIENT->value, $roles, true) || ! in_array(UserRole::DOCTOR->value, $roles, true)) {
            throw ValidationException::withMessages([
                'participant_user_id' => ['Only patient-doctor conversations are allowed.'],
            ]);
        }

        $query = Appointment::query()->where(function (Builder $builder) use ($actor, $peer): void {
            $builder
                ->where('patient_user_id', $actor->id)
                ->where('doctor_user_id', $peer->id);
        })->orWhere(function (Builder $builder) use ($actor, $peer): void {
            $builder
                ->where('patient_user_id', $peer->id)
                ->where('doctor_user_id', $actor->id);
        });

        if ($consultationId !== null) {
            $query->where('id', $consultationId);
        }

        $consultation = $query
            ->whereIn('status', ['REQUESTED', 'CONFIRMED', 'COMPLETED'])
            ->orderByDesc('starts_at_utc')
            ->first();

        if ($consultation === null) {
            throw new AuthorizationException('No authorized consultation found for this conversation.');
        }

        return $consultation;
    }

    public function assertParticipant(Conversation $conversation, User $user): void
    {
        $isParticipant = $conversation->participants()
            ->where('user_id', $user->id)
            ->where('is_active', true)
            ->exists();

        if (! $isParticipant) {
            throw new AuthorizationException('You are not allowed to access this conversation.');
        }
    }

    private function roleFor(User $user): ConversationParticipantRole
    {
        return ($user->role?->value ?? $user->role) === UserRole::DOCTOR->value
            ? ConversationParticipantRole::DOCTOR
            : ConversationParticipantRole::PATIENT;
    }
}
