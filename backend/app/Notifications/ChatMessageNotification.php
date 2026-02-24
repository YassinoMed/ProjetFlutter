<?php

namespace App\Notifications;

use App\Models\ChatMessage;
use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class ChatMessageNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(private readonly ChatMessage $message) {}

    public function via(User $notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm(User $notifiable): array
    {
        return [
            'title' => 'Nouveau message',
            'body' => 'Vous avez reçu un nouveau message sécurisé.',
            'data' => [
                'type' => 'CHAT',
                'event' => 'message',
                'consultation_id' => $this->message->consultation_id,
                'message_id' => $this->message->id,
                'sender_user_id' => $this->message->sender_user_id,
                'sent_at_utc' => optional($this->message->sent_at_utc)?->setTimezone('UTC')?->toISOString(),
            ],
        ];
    }
}
