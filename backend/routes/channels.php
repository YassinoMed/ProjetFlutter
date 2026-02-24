<?php

use App\Models\Appointment;
use Illuminate\Support\Facades\Broadcast;

if (app()->environment('testing')) {
    return;
}

Broadcast::channel('consultations.{consultationId}', function ($user, string $consultationId): bool {
    $appointment = Appointment::query()->find($consultationId);

    if ($appointment === null) {
        return false;
    }

    return $user->id === $appointment->patient_user_id
        || $user->id === $appointment->doctor_user_id;
});
