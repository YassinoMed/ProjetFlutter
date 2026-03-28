<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppointmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'patient_user_id' => $this->patient_user_id,
            'doctor_user_id' => $this->doctor_user_id,
            'patient_name' => trim((string) ($this->patient?->first_name ?? '').' '.(string) ($this->patient?->last_name ?? '')),
            'doctor_name' => trim((string) ($this->doctor?->first_name ?? '').' '.(string) ($this->doctor?->last_name ?? '')),
            'starts_at_utc' => optional($this->starts_at_utc)?->setTimezone('UTC')?->toISOString(),
            'ends_at_utc' => optional($this->ends_at_utc)?->setTimezone('UTC')?->toISOString(),
            'status' => $this->status?->value ?? $this->status,
            'metadata_encrypted' => $this->metadata_encrypted,
            'cancel_reason' => $this->cancel_reason,
            'created_at_utc' => optional($this->created_at)?->setTimezone('UTC')?->toISOString(),
            'updated_at_utc' => optional($this->updated_at)?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
