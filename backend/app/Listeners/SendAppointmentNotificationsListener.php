<?php

namespace App\Listeners;

use App\Events\AppointmentStatusChanged;
use App\Jobs\SendAppointmentReminderJob;
use App\Notifications\AppointmentStatusNotification;
use Illuminate\Support\Carbon;

class SendAppointmentNotificationsListener
{
    public function handle(AppointmentStatusChanged $event): void
    {
        if (app()->environment('testing')) {
            return;
        }

        $appointment = $event->appointment->refresh();

        if ($event->event === 'confirmed') {
            $appointment->patient?->notify(new AppointmentStatusNotification($appointment, 'confirmed'));
            $appointment->doctor?->notify(new AppointmentStatusNotification($appointment, 'confirmed'));

            $this->scheduleReminder($appointment->id, 'reminder_j1', Carbon::parse($appointment->starts_at_utc, 'UTC')->subDay());
            $this->scheduleReminder($appointment->id, 'reminder_h1', Carbon::parse($appointment->starts_at_utc, 'UTC')->subHour());
        }

        if ($event->event === 'cancelled') {
            $appointment->patient?->notify(new AppointmentStatusNotification($appointment, 'cancelled'));
            $appointment->doctor?->notify(new AppointmentStatusNotification($appointment, 'cancelled'));
        }
    }

    private function scheduleReminder(string $appointmentId, string $event, Carbon $whenUtc): void
    {
        $job = new SendAppointmentReminderJob($appointmentId, $event);

        if ($whenUtc->lte(now('UTC'))) {
            dispatch($job);

            return;
        }

        dispatch($job)->delay($whenUtc);
    }
}
