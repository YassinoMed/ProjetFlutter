<?php

namespace App\Services;

use App\Enums\DelegationStatus;
use App\Enums\SecretaryPermission;
use App\Enums\UserRole;
use App\Models\Appointment;
use App\Models\DoctorSecretaryDelegation;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class DelegationContextService
{
    public function resolveForRequest(Request $request): ?DoctorSecretaryDelegation
    {
        /** @var User|null $user */
        $user = $request->user();

        if ($user === null || $user->role !== UserRole::SECRETARY) {
            return null;
        }

        $doctorUserId = $request->header('X-Acting-Doctor-Id');

        if ($doctorUserId === null || $doctorUserId === '') {
            throw ValidationException::withMessages([
                'context' => ['Secretary requests must include X-Acting-Doctor-Id.'],
            ]);
        }

        $delegation = DoctorSecretaryDelegation::query()
            ->with('permissions')
            ->where('secretary_user_id', $user->id)
            ->where('doctor_user_id', $doctorUserId)
            ->where('status', DelegationStatus::ACTIVE->value)
            ->first();

        if ($delegation === null) {
            throw new AuthorizationException('No active delegation found for this doctor context.');
        }

        $request->attributes->set('doctor_delegation', $delegation);
        $request->attributes->set('acting_doctor_user_id', $delegation->doctor_user_id);

        return $delegation;
    }

    public function effectiveDoctorUserId(Request $request): ?string
    {
        /** @var User|null $user */
        $user = $request->user();

        if ($user === null) {
            return null;
        }

        if ($user->role === UserRole::DOCTOR) {
            return $user->id;
        }

        return $request->attributes->get('acting_doctor_user_id');
    }

    public function assertSecretaryPermission(Request $request, SecretaryPermission $permission): DoctorSecretaryDelegation
    {
        $delegation = $this->resolveForRequest($request);

        if ($delegation === null) {
            throw new AuthorizationException('This request is not running in a secretary delegation context.');
        }

        $allowed = $delegation->permissions->contains(
            fn ($granted) => ($granted->permission?->value ?? $granted->permission) === $permission->value
        );

        if (! $allowed) {
            throw new AuthorizationException("Missing delegation permission {$permission->value}.");
        }

        return $delegation;
    }

    public function canAccessAppointment(Request $request, Appointment $appointment, SecretaryPermission $permission): bool
    {
        /** @var User $user */
        $user = $request->user();

        if ($user->role === UserRole::DOCTOR && $appointment->doctor_user_id === $user->id) {
            return true;
        }

        if ($user->role !== UserRole::SECRETARY) {
            return false;
        }

        $delegation = $this->assertSecretaryPermission($request, $permission);

        return $appointment->doctor_user_id === $delegation->doctor_user_id;
    }
}
