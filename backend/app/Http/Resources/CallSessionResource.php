<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CallSessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'consultation_id' => $this->consultation_id,
            'conversation_id' => $this->conversation_id,
            'initiated_by_user_id' => $this->initiated_by_user_id,
            'ended_by_user_id' => $this->ended_by_user_id,
            'call_type' => $this->call_type?->value ?? $this->call_type,
            'current_state' => $this->current_state?->value ?? $this->current_state,
            'started_ringing_at_utc' => optional($this->started_ringing_at_utc)?->setTimezone('UTC')?->toISOString(),
            'accepted_at_utc' => optional($this->accepted_at_utc)?->setTimezone('UTC')?->toISOString(),
            'ended_at_utc' => optional($this->ended_at_utc)?->setTimezone('UTC')?->toISOString(),
            'expires_at_utc' => optional($this->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
            'end_reason' => $this->end_reason,
            'server_metadata' => $this->server_metadata,
            'participants' => $this->whenLoaded('participants', fn () => $this->participants->map(fn ($participant) => [
                'user_id' => $participant->user_id,
                'role' => $participant->role?->value ?? $participant->role,
                'joined_at_utc' => optional($participant->joined_at_utc)?->setTimezone('UTC')?->toISOString(),
                'left_at_utc' => optional($participant->left_at_utc)?->setTimezone('UTC')?->toISOString(),
            ])->values()->all()),
        ];
    }
}
