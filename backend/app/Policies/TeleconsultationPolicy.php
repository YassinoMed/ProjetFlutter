<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Teleconsultation;
use App\Models\User;

class TeleconsultationPolicy
{
    public function view(User $user, Teleconsultation $teleconsultation): bool
    {
        if (($user->role?->value ?? $user->role) === UserRole::ADMIN->value) {
            return true;
        }

        return $teleconsultation->patient_user_id === $user->id
            || $teleconsultation->doctor_user_id === $user->id
            || $teleconsultation->participants()
                ->where('user_id', $user->id)
                ->whereNull('access_revoked_at_utc')
                ->exists();
    }

    public function create(User $user): bool
    {
        return in_array($user->role?->value ?? $user->role, [
            UserRole::PATIENT->value,
            UserRole::DOCTOR->value,
            UserRole::SECRETARY->value,
            UserRole::ADMIN->value,
        ], true);
    }

    public function start(User $user, Teleconsultation $teleconsultation): bool
    {
        return ($user->role?->value ?? $user->role) === UserRole::ADMIN->value
            || $teleconsultation->doctor_user_id === $user->id;
    }

    public function join(User $user, Teleconsultation $teleconsultation): bool
    {
        if (($user->role?->value ?? $user->role) === UserRole::ADMIN->value) {
            return false;
        }

        return $this->view($user, $teleconsultation)
            && in_array($user->id, [$teleconsultation->patient_user_id, $teleconsultation->doctor_user_id], true);
    }

    public function cancel(User $user, Teleconsultation $teleconsultation): bool
    {
        return $this->view($user, $teleconsultation);
    }

    public function end(User $user, Teleconsultation $teleconsultation): bool
    {
        return $this->join($user, $teleconsultation);
    }
}
