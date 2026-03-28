<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CallEventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'teleconsultation_id' => $this->teleconsultation_id,
            'call_session_id' => $this->call_session_id,
            'actor_user_id' => $this->actor_user_id,
            'target_user_id' => $this->target_user_id,
            'event_name' => $this->event_name,
            'direction' => $this->direction,
            'payload' => $this->payload,
            'occurred_at_utc' => optional($this->occurred_at_utc)?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
