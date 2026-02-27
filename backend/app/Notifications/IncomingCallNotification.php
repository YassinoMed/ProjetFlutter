<?php

namespace App\Notifications;

use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class IncomingCallNotification extends Notification
{
    use Queueable;

    public function __construct(
        private readonly string $appointmentId,
        private readonly User $caller,
        private readonly string $callType, // 'video' or 'audio'
    ) {}

    public function via(object $notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm(object $notifiable): array
    {
        $callerName = "{$this->caller->first_name} {$this->caller->last_name}";

        return [
            'notification' => [
                'title' => 'Appel entrant',
                'body' => "Dr. {$callerName} vous appelle en {$this->callType}consultation",
            ],
            'data' => [
                'type' => 'incoming_call',
                'appointment_id' => $this->appointmentId,
                'caller_user_id' => $this->caller->id,
                'caller_name' => $callerName,
                'call_type' => $this->callType,
                'timestamp_utc' => now('UTC')->toISOString(),
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'incoming_calls',
                    'sound' => 'ringtone',
                    'default_vibrate_timings' => true,
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-push-type' => 'voip',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => [
                            'title' => 'Appel entrant',
                            'body' => "Dr. {$callerName} vous appelle",
                        ],
                        'sound' => 'ringtone.caf',
                        'content-available' => 1,
                    ],
                ],
            ],
        ];
    }
}
