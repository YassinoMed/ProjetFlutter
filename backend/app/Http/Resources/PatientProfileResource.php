<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PatientProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'user_id' => $this->user_id,
            'date_of_birth' => optional($this->date_of_birth)->format('Y-m-d'),
            'sex' => $this->sex,
            'created_at_utc' => optional($this->created_at)?->setTimezone('UTC')->toISOString(),
            'updated_at_utc' => optional($this->updated_at)?->setTimezone('UTC')->toISOString(),
        ];
    }
}
