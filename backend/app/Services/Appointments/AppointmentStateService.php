<?php

namespace App\Services\Appointments;

use App\Enums\AppointmentStatus;
use App\Events\AppointmentStatusChanged;
use App\Models\Appointment;
use App\Models\AppointmentEvent;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AppointmentStateService
{
    public function transition(
        Appointment $appointment,
        AppointmentStatus $to,
        ?string $actorUserId,
        ?array $metadataEncrypted = null,
        ?string $cancelReason = null,
    ): Appointment {
        $from = $appointment->status;

        if (! $from->canTransitionTo($to)) {
            throw ValidationException::withMessages([
                'status' => ['Invalid state transition'],
            ]);
        }

        return DB::transaction(function () use ($appointment, $from, $to, $actorUserId, $metadataEncrypted, $cancelReason): Appointment {
            $appointment = Appointment::query()->whereKey($appointment->id)->lockForUpdate()->firstOrFail();

            if (! $appointment->status->canTransitionTo($to)) {
                throw ValidationException::withMessages([
                    'status' => ['Invalid state transition'],
                ]);
            }

            $update = ['status' => $to];

            if ($to === AppointmentStatus::CANCELLED) {
                $update['cancel_reason'] = $cancelReason;
            }

            $appointment->update($update);

            AppointmentEvent::query()->create([
                'appointment_id' => $appointment->id,
                'actor_user_id' => $actorUserId,
                'from_status' => $from->value,
                'to_status' => $to->value,
                'metadata_encrypted' => $metadataEncrypted,
                'occurred_at_utc' => now('UTC'),
            ]);

            DB::afterCommit(function () use ($appointment, $to) {
                $event = match ($to) {
                    AppointmentStatus::CONFIRMED => 'confirmed',
                    AppointmentStatus::CANCELLED => 'cancelled',
                    default => 'status_changed',
                };

                event(new AppointmentStatusChanged($appointment, $event));
            });

            return $appointment->refresh();
        });
    }
}
