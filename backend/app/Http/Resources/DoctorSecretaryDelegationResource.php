<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DoctorSecretaryDelegationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'doctor_user_id' => $this->doctor_user_id,
            'doctor' => $this->whenLoaded('doctor', fn () => [
                'id' => $this->doctor->id,
                'first_name' => $this->doctor->first_name,
                'last_name' => $this->doctor->last_name,
                'email' => $this->doctor->email,
            ]),
            'secretary_user_id' => $this->secretary_user_id,
            'secretary' => $this->whenLoaded('secretary', fn () => [
                'id' => $this->secretary->id,
                'first_name' => $this->secretary->first_name,
                'last_name' => $this->secretary->last_name,
                'email' => $this->secretary->email,
            ]),
            'invited_email' => $this->invited_email,
            'invited_first_name' => $this->invited_first_name,
            'invited_last_name' => $this->invited_last_name,
            'status' => $this->status?->value ?? $this->status,
            'permissions' => $this->whenLoaded('permissions', fn () => $this->permissions->map(
                fn ($permission) => $permission->permission?->value ?? $permission->permission
            )->values()->all()),
            'activated_at_utc' => optional($this->activated_at_utc)?->setTimezone('UTC')?->toISOString(),
            'suspended_at_utc' => optional($this->suspended_at_utc)?->setTimezone('UTC')?->toISOString(),
            'revoked_at_utc' => optional($this->revoked_at_utc)?->setTimezone('UTC')?->toISOString(),
            'last_used_at_utc' => optional($this->last_used_at_utc)?->setTimezone('UTC')?->toISOString(),
            'latest_invitation' => $this->whenLoaded('invitations', function () {
                $latestInvitation = $this->invitations->sortByDesc('created_at')->first();

                if ($latestInvitation === null) {
                    return null;
                }

                return [
                    'status' => $latestInvitation->status?->value ?? $latestInvitation->status,
                    'expires_at_utc' => optional($latestInvitation->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
                    'accepted_at_utc' => optional($latestInvitation->accepted_at_utc)?->setTimezone('UTC')?->toISOString(),
                ];
            }),
        ];
    }
}
