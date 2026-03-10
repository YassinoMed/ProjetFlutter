<?php

namespace App\Notifications;

use App\Models\CallSession;
use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class IncomingCallSessionNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly CallSession $callSession,
        private readonly User $caller,
    ) {}

    public function via(User $notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm(User $notifiable): array
    {
        return [
            'title' => 'Appel entrant',
            'body' => trim("{$this->caller->first_name} {$this->caller->last_name} vous appelle."),
            'priority' => 'high',
            'data' => [
                'type' => 'CALL',
                'event' => 'webrtc.ringing',
                'call_session_id' => $this->callSession->id,
                'conversation_id' => $this->callSession->conversation_id,
                'consultation_id' => $this->callSession->consultation_id,
                'caller_user_id' => $this->caller->id,
                'call_type' => $this->callSession->call_type?->value ?? $this->callSession->call_type,
                'expires_at_utc' => optional($this->callSession->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
            ],
        ];
    }
}
