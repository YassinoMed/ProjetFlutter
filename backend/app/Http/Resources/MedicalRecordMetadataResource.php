<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MedicalRecordMetadataResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'patient_user_id' => $this->patient_user_id,
            'doctor_user_id' => $this->doctor_user_id,
            'category' => $this->category,
            'metadata_encrypted' => $this->metadata_encrypted,
            'recorded_at_utc' => optional($this->recorded_at_utc)?->setTimezone('UTC')->toISOString(),
            'created_at_utc' => optional($this->created_at)?->setTimezone('UTC')->toISOString(),
            'updated_at_utc' => optional($this->updated_at)?->setTimezone('UTC')->toISOString(),
        ];
    }
}
