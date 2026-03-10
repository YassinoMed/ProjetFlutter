<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationParticipantResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'user_id' => $this->user_id,
            'role' => $this->role?->value ?? $this->role,
            'is_active' => (bool) $this->is_active,
            'joined_at_utc' => optional($this->joined_at_utc)?->setTimezone('UTC')?->toISOString(),
            'last_seen_at_utc' => optional($this->last_seen_at_utc)?->setTimezone('UTC')?->toISOString(),
            'last_delivered_at_utc' => optional($this->last_delivered_at_utc)?->setTimezone('UTC')?->toISOString(),
            'last_read_at_utc' => optional($this->last_read_at_utc)?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
