<?php

namespace App\Notifications;

use App\Models\Message;
use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class SecureMessageNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(private readonly Message $message) {}

    public function via(User $notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm(User $notifiable): array
    {
        return [
            'title' => 'Nouveau message securise',
            'body' => 'Vous avez recu un nouveau message dans MediConnect Pro.',
            'data' => [
                'type' => 'CHAT',
                'event' => 'message.new',
                'conversation_id' => $this->message->conversation_id,
                'message_id' => $this->message->id,
                'sender_user_id' => $this->message->sender_user_id,
                'sent_at_utc' => optional($this->message->sent_at_utc)?->setTimezone('UTC')?->toISOString(),
            ],
        ];
    }
}
