<?php

namespace App\Services\Appointments;

use App\Enums\AppointmentStatus;
use App\Events\AppointmentStatusChanged;
use App\Models\Appointment;
use App\Models\AppointmentEvent;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AppointmentBookingService
{
    public function createRequested(
        string $patientUserId,
        string $doctorUserId,
        Carbon $startsAtUtc,
        Carbon $endsAtUtc,
        ?array $metadataEncrypted,
    ): Appointment {
        if ($endsAtUtc->lte($startsAtUtc)) {
            throw ValidationException::withMessages([
                'ends_at_utc' => ['End must be after start'],
            ]);
        }

        return DB::transaction(function () use ($patientUserId, $doctorUserId, $startsAtUtc, $endsAtUtc, $metadataEncrypted) {
            User::query()->where('id', $doctorUserId)->lockForUpdate()->firstOrFail();

            $conflictingDoctor = Appointment::query()
                ->where('doctor_user_id', $doctorUserId)
                ->whereIn('status', [AppointmentStatus::REQUESTED, AppointmentStatus::CONFIRMED])
                ->where(function ($q) use ($startsAtUtc, $endsAtUtc) {
                    $q->where('starts_at_utc', '<', $endsAtUtc)
                        ->where('ends_at_utc', '>', $startsAtUtc);
                })
                ->lockForUpdate()
                ->exists();

            if ($conflictingDoctor) {
                throw ValidationException::withMessages([
                    'starts_at_utc' => ['Doctor slot is not available'],
                ]);
            }

            $conflictingPatient = Appointment::query()
                ->where('patient_user_id', $patientUserId)
                ->whereIn('status', [AppointmentStatus::REQUESTED, AppointmentStatus::CONFIRMED])
                ->where(function ($q) use ($startsAtUtc, $endsAtUtc) {
                    $q->where('starts_at_utc', '<', $endsAtUtc)
                        ->where('ends_at_utc', '>', $startsAtUtc);
                })
                ->lockForUpdate()
                ->exists();

            if ($conflictingPatient) {
                throw ValidationException::withMessages([
                    'starts_at_utc' => ['Patient has another appointment at this time'],
                ]);
            }

            $appointment = Appointment::query()->create([
                'patient_user_id' => $patientUserId,
                'doctor_user_id' => $doctorUserId,
                'starts_at_utc' => $startsAtUtc,
                'ends_at_utc' => $endsAtUtc,
                'status' => AppointmentStatus::REQUESTED,
                'metadata_encrypted' => $metadataEncrypted,
            ]);

            AppointmentEvent::query()->create([
                'appointment_id' => $appointment->id,
                'actor_user_id' => $patientUserId,
                'from_status' => null,
                'to_status' => AppointmentStatus::REQUESTED->value,
                'metadata_encrypted' => null,
                'occurred_at_utc' => now('UTC'),
            ]);

            DB::afterCommit(fn () => event(new AppointmentStatusChanged($appointment, 'requested')));

            return $appointment;
        });
    }
}
