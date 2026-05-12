<?php

namespace App\Http\Resources;

use App\Models\CallSession;
use BackedEnum;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CallSessionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        /** @var CallSession $callSession */
        $callSession = $this->resource;
        $serverMetadata = $callSession->server_metadata;

        return [
            'id' => $callSession->id,
            'consultation_id' => $callSession->consultation_id,
            'conversation_id' => $callSession->conversation_id,
            'initiated_by_user_id' => $callSession->initiated_by_user_id,
            'ended_by_user_id' => $callSession->ended_by_user_id,
            'call_type' => $this->enumValue($callSession->call_type),
            'current_state' => $this->enumValue($callSession->current_state),
            'started_ringing_at_utc' => optional($callSession->started_ringing_at_utc)?->setTimezone('UTC')?->toISOString(),
            'accepted_at_utc' => optional($callSession->accepted_at_utc)?->setTimezone('UTC')?->toISOString(),
            'ended_at_utc' => optional($callSession->ended_at_utc)?->setTimezone('UTC')?->toISOString(),
            'expires_at_utc' => optional($callSession->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
            'end_reason' => $callSession->end_reason,
            'server_metadata' => $serverMetadata,
            'media_provider' => data_get($serverMetadata, 'media_provider'),
            'livekit_room' => data_get($serverMetadata, 'livekit_room'),
            'participants' => $this->whenLoaded('participants', fn () => $callSession->participants->map(fn ($participant) => [
                'user_id' => $participant->getAttribute('user_id'),
                'role' => $this->enumValue($participant->getAttribute('role')),
                'joined_at_utc' => optional($participant->getAttribute('joined_at_utc'))?->setTimezone('UTC')?->toISOString(),
                'left_at_utc' => optional($participant->getAttribute('left_at_utc'))?->setTimezone('UTC')?->toISOString(),
            ])->values()->all()),
        ];
    }

    private function enumValue(mixed $value): mixed
    {
        return $value instanceof BackedEnum ? $value->value : $value;
    }
}
