<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'consultation_id' => $this->consultation_id,
            'type' => $this->type?->value ?? $this->type,
            'last_message_at_utc' => optional($this->last_message_at_utc)?->setTimezone('UTC')?->toISOString(),
            'server_metadata' => $this->server_metadata,
            'participants' => ConversationParticipantResource::collection($this->whenLoaded('participants')),
            'created_at' => optional($this->created_at)?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
