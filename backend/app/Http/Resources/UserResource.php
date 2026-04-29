<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $data = [
            'id' => $this->id,
            'email' => $this->email,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'phone' => $this->phone,
            'role' => $this->role?->value ?? $this->role,
            'created_at_utc' => optional($this->created_at)->setTimezone('UTC')?->toISOString(),
            'updated_at_utc' => optional($this->updated_at)->setTimezone('UTC')?->toISOString(),
        ];

        $roleValue = $this->role instanceof \App\Enums\UserRole ? $this->role->value : $this->role;
        if ($roleValue === 'doctor') {
            $data['specialty'] = $this->doctorProfile?->specialty;
            $data['license_number'] = $this->doctorProfile?->rpps;
            $data['speciality'] = $this->doctorProfile?->specialty; // To ensure compatibility with frontend typo
        }

        if ($roleValue === 'patient') {
            $data['date_of_birth'] = $this->patientProfile?->date_of_birth;
            $data['sex'] = $this->patientProfile?->sex;
        }

        return $data;
    }
}
