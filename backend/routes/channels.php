<?php

use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Models\Teleconsultation;
use App\Enums\UserRole;
use App\Services\Teleconsultations\TeleconsultationSchemaGuard;
use Illuminate\Support\Facades\Broadcast;

if (app()->environment('testing')) {
    return;
}

Broadcast::channel('consultations.{consultationId}', function ($user, string $consultationId): bool {
    $appointment = Appointment::query()->find($consultationId);

    if ($appointment === null) {
        return false;
    }

    return $user->id === $appointment->patient_user_id
        || $user->id === $appointment->doctor_user_id;
});

Broadcast::channel('conversations.{conversationId}', function ($user, string $conversationId): bool {
    return Conversation::query()
        ->whereKey($conversationId)
        ->whereHas('participants', function ($query) use ($user): void {
            $query->where('user_id', $user->id)->where('is_active', true);
        })
        ->exists();
});

Broadcast::channel('conversations.{conversationId}.presence', function ($user, string $conversationId): array|bool {
    $conversation = Conversation::query()
        ->with(['participants' => fn ($query) => $query->where('user_id', $user->id)])
        ->find($conversationId);

    if ($conversation === null || $conversation->participants->isEmpty()) {
        return false;
    }

    $participant = $conversation->participants->first();

    return [
        'id' => $user->id,
        'role' => $participant->role?->value ?? $participant->role,
        'name' => trim(($user->first_name ?? '').' '.($user->last_name ?? '')),
    ];
});

Broadcast::channel('calls.{callSessionId}', function ($user, string $callSessionId): bool {
    return CallSession::query()
        ->whereKey($callSessionId)
        ->whereHas('participants', function ($query) use ($user): void {
            $query->where('user_id', $user->id);
        })
        ->exists();
});

Broadcast::channel('calls.{callSessionId}.presence', function ($user, string $callSessionId): array|bool {
    $callSession = CallSession::query()
        ->with(['participants' => fn ($query) => $query->where('user_id', $user->id)])
        ->find($callSessionId);

    if ($callSession === null || $callSession->participants->isEmpty()) {
        return false;
    }

    $participant = $callSession->participants->first();

    return [
        'id' => $user->id,
        'role' => $participant->role?->value ?? $participant->role,
        'name' => trim(($user->first_name ?? '').' '.($user->last_name ?? '')),
    ];
});

Broadcast::channel('teleconsultations.{teleconsultationId}', function ($user, string $teleconsultationId): bool {
    if (! app(TeleconsultationSchemaGuard::class)->isAvailable()) {
        return false;
    }

    if (($user->role?->value ?? $user->role) === UserRole::ADMIN->value) {
        return true;
    }

    return Teleconsultation::query()
        ->whereKey($teleconsultationId)
        ->where(function ($query) use ($user): void {
            $query
                ->where('patient_user_id', $user->id)
                ->orWhere('doctor_user_id', $user->id)
                ->orWhereHas('participants', function ($participantQuery) use ($user): void {
                    $participantQuery
                        ->where('user_id', $user->id)
                        ->whereNull('access_revoked_at_utc');
                });
        })
        ->exists();
});
