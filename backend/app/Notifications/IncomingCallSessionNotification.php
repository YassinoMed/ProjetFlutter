<?php

namespace App\Notifications;

use App\Models\CallSession;
use App\Models\Teleconsultation;
use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use App\Services\Teleconsultations\TeleconsultationSchemaGuard;
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
        $teleconsultation = app(TeleconsultationSchemaGuard::class)->isAvailable()
            ? Teleconsultation::query()
                ->where('current_call_session_id', $this->callSession->id)
                ->orWhere('appointment_id', $this->callSession->consultation_id)
                ->first()
            : null;

        $callerName = trim("{$this->caller->first_name} {$this->caller->last_name}");

        return [
            'title' => 'Appel entrant',
            'body' => trim("{$callerName} vous appelle."),
            'category' => 'CALL_ACTIONS',
            'priority' => 'high',
            'actions' => [
                ['id' => 'accept', 'title' => 'Accepter', 'action' => 'ACCEPT_CALL'],
                ['id' => 'decline', 'title' => 'Refuser', 'action' => 'DECLINE_CALL'],
            ],
            'data' => [
                'type' => 'CALL',
                'event' => 'webrtc.ringing',
                'teleconsultation_id' => $teleconsultation?->id,
                'call_session_id' => $this->callSession->id,
                'conversation_id' => $this->callSession->conversation_id,
                'consultation_id' => $this->callSession->consultation_id,
                'appointment_id' => $this->callSession->consultation_id,
                'caller_user_id' => $this->caller->id,
                'caller_name' => $callerName,
                'call_type' => $this->callSession->call_type?->value ?? $this->callSession->call_type,
                'expires_at_utc' => optional($this->callSession->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
                'deep_link' => $teleconsultation !== null
                    ? '/teleconsultations/incoming/'.$teleconsultation->id
                    : '/video-call/'.$this->callSession->consultation_id,
            ],
        ];
    }
}
