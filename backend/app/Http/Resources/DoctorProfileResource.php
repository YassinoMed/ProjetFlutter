<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DoctorProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'user_id' => $this->user_id,
            'rpps' => $this->rpps,
            'specialty' => $this->specialty,
            'created_at_utc' => optional($this->created_at)?->setTimezone('UTC')->toISOString(),
            'updated_at_utc' => optional($this->updated_at)?->setTimezone('UTC')->toISOString(),
        ];
    }
}
