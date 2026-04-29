<?php

namespace App\Http\Resources;

use App\Enums\TeleconsultationStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TeleconsultationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $status = $this->status?->value ?? $this->status;
        $userId = $request->user()?->id;

        return [
            'id' => $this->id,
            'appointment_id' => $this->appointment_id,
            'conversation_id' => $this->conversation_id,
            'current_call_session_id' => $this->current_call_session_id,
            'patient_user_id' => $this->patient_user_id,
            'doctor_user_id' => $this->doctor_user_id,
            'call_type' => $this->call_type?->value ?? $this->call_type,
            'status' => $status,
            'scheduled_starts_at_utc' => optional($this->scheduled_starts_at_utc)?->setTimezone('UTC')?->toISOString(),
            'scheduled_ends_at_utc' => optional($this->scheduled_ends_at_utc)?->setTimezone('UTC')?->toISOString(),
            'ringing_started_at_utc' => optional($this->ringing_started_at_utc)?->setTimezone('UTC')?->toISOString(),
            'started_at_utc' => optional($this->started_at_utc)?->setTimezone('UTC')?->toISOString(),
            'ended_at_utc' => optional($this->ended_at_utc)?->setTimezone('UTC')?->toISOString(),
            'expires_at_utc' => optional($this->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
            'cancellation_reason' => $this->cancellation_reason,
            'failure_reason' => $this->failure_reason,
            'server_metadata' => $this->server_metadata,
            'can_start' => $userId !== null
                && $userId === $this->doctor_user_id
                && $status === TeleconsultationStatus::SCHEDULED->value,
            'can_join' => $userId !== null
                && in_array($status, [
                    TeleconsultationStatus::WAITING->value,
                    TeleconsultationStatus::ACTIVE->value,
                ], true)
                && in_array($userId, [$this->patient_user_id, $this->doctor_user_id], true),
            'participants' => $this->whenLoaded('participants', fn () => $this->participants->map(fn ($participant) => [
                'user_id' => $participant->user_id,
                'role' => $participant->role?->value ?? $participant->role,
                'invited_at_utc' => optional($participant->invited_at_utc)?->setTimezone('UTC')?->toISOString(),
                'joined_at_utc' => optional($participant->joined_at_utc)?->setTimezone('UTC')?->toISOString(),
                'left_at_utc' => optional($participant->left_at_utc)?->setTimezone('UTC')?->toISOString(),
                'last_seen_at_utc' => optional($participant->last_seen_at_utc)?->setTimezone('UTC')?->toISOString(),
                'can_publish_audio' => (bool) $participant->can_publish_audio,
                'can_publish_video' => (bool) $participant->can_publish_video,
                'access_revoked_at_utc' => optional($participant->access_revoked_at_utc)?->setTimezone('UTC')?->toISOString(),
            ])->values()->all()),
            'current_call_session' => $this->whenLoaded(
                'currentCallSession',
                fn () => $this->currentCallSession === null ? null : (new CallSessionResource($this->currentCallSession))->resolve()
            ),
            'created_at_utc' => optional($this->created_at)?->setTimezone('UTC')?->toISOString(),
            'updated_at_utc' => optional($this->updated_at)?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
