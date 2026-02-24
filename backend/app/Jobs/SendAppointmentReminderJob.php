<?php

namespace App\Jobs;

use App\Models\Appointment;
use App\Notifications\AppointmentStatusNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendAppointmentReminderJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function __construct(
        public readonly string $appointmentId,
        public readonly string $event,
    ) {}

    public function handle(): void
    {
        $appointment = Appointment::query()->find($this->appointmentId);

        if ($appointment === null) {
            return;
        }

        $notification = new AppointmentStatusNotification($appointment, $this->event);

        $appointment->patient?->notify($notification);
        $appointment->doctor?->notify($notification);
    }
}
