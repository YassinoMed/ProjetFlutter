<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\DoctorSecretaryDelegation;
use App\Models\User;

class DoctorSecretaryDelegationPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, [UserRole::DOCTOR, UserRole::ADMIN], true);
    }

    public function create(User $user): bool
    {
        return in_array($user->role, [UserRole::DOCTOR, UserRole::ADMIN], true);
    }

    public function update(User $user, DoctorSecretaryDelegation $delegation): bool
    {
        return $user->role === UserRole::ADMIN || $delegation->doctor_user_id === $user->id;
    }

    public function delete(User $user, DoctorSecretaryDelegation $delegation): bool
    {
        return $this->update($user, $delegation);
    }
}
