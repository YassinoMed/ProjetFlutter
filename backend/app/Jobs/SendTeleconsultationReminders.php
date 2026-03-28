<?php

namespace App\Jobs;

use App\Enums\TeleconsultationStatus;
use App\Models\CallEvent;
use App\Models\Teleconsultation;
use App\Notifications\TeleconsultationReminderNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendTeleconsultationReminders implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function handle(): void
    {
        $this->dispatchWindow('24h', now('UTC')->addHours(23)->addMinutes(30), now('UTC')->addHours(24)->addMinutes(30));
        $this->dispatchWindow('1h', now('UTC')->addMinutes(50), now('UTC')->addMinutes(70));
    }

    private function dispatchWindow(string $window, \Illuminate\Support\Carbon $from, \Illuminate\Support\Carbon $to): void
    {
        $eventName = 'teleconsultation.reminder.'.$window;

        Teleconsultation::query()
            ->with(['patient', 'doctor'])
            ->where('status', TeleconsultationStatus::SCHEDULED->value)
            ->whereBetween('scheduled_starts_at_utc', [$from, $to])
            ->get()
            ->each(function (Teleconsultation $teleconsultation) use ($window, $eventName): void {
                $alreadySent = CallEvent::query()
                    ->where('teleconsultation_id', $teleconsultation->id)
                    ->where('event_name', $eventName)
                    ->exists();

                if ($alreadySent) {
                    return;
                }

                $notification = new TeleconsultationReminderNotification($teleconsultation, $window);

                $teleconsultation->patient?->notify($notification);
                $teleconsultation->doctor?->notify($notification);

                CallEvent::query()->create([
                    'teleconsultation_id' => $teleconsultation->id,
                    'call_session_id' => $teleconsultation->current_call_session_id,
                    'actor_user_id' => null,
                    'target_user_id' => null,
                    'event_name' => $eventName,
                    'direction' => 'server_to_client',
                    'payload' => [
                        'window' => $window,
                        'starts_at_utc' => optional($teleconsultation->scheduled_starts_at_utc)?->setTimezone('UTC')?->toISOString(),
                    ],
                    'occurred_at_utc' => now('UTC'),
                ]);
            });
    }
}
