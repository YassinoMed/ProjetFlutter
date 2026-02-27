<?php

namespace App\Jobs;

use App\Enums\AppointmentStatus;
use App\Models\Appointment;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendAppointmentReminders implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function handle(NotificationService $notifications): void
    {
        // 24h reminders
        $upcoming24h = Appointment::query()
            ->where('status', AppointmentStatus::CONFIRMED)
            ->whereBetween('starts_at_utc', [
                now('UTC')->addHours(23)->addMinutes(30),
                now('UTC')->addHours(24)->addMinutes(30),
            ])
            ->get();

        foreach ($upcoming24h as $appointment) {
            $notifications->notifyAppointmentReminder($appointment, '24h');
        }

        // 1h reminders
        $upcoming1h = Appointment::query()
            ->where('status', AppointmentStatus::CONFIRMED)
            ->whereBetween('starts_at_utc', [
                now('UTC')->addMinutes(50),
                now('UTC')->addMinutes(70),
            ])
            ->get();

        foreach ($upcoming1h as $appointment) {
            $notifications->notifyAppointmentReminder($appointment, '1h');
        }
    }
}
