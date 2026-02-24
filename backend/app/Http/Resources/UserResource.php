<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'email' => $this->email,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'phone' => $this->phone,
            'role' => $this->role?->value ?? $this->role,
            'created_at_utc' => optional($this->created_at)->setTimezone('UTC')?->toISOString(),
            'updated_at_utc' => optional($this->updated_at)->setTimezone('UTC')?->toISOString(),
        ];
    }
}
