<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Appointment;
use App\Models\User;

class AppointmentPolicy
{
    public function view(User $user, Appointment $appointment): bool
    {
        return $user->id === $appointment->patient_user_id
            || $user->id === $appointment->doctor_user_id
            || $user->role === UserRole::ADMIN;
    }

    public function update(User $user, Appointment $appointment): bool
    {
        return $this->view($user, $appointment);
    }

    public function confirm(User $user, Appointment $appointment): bool
    {
        return $user->id === $appointment->doctor_user_id || $user->role === UserRole::ADMIN;
    }
}
