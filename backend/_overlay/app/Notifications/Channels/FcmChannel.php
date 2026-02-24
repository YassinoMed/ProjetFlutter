<?php

namespace App\Notifications\Channels;

use App\Models\User;
use Illuminate\Notifications\Notification;
use Kreait\Firebase\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

class FcmChannel
{
    public function __construct(private readonly Messaging $messaging) {}

    public function send(object $notifiable, Notification $notification): void
    {
        if (! $notifiable instanceof User) {
            return;
        }

        if (! method_exists($notification, 'toFcm')) {
            return;
        }

        $payload = $notification->toFcm($notifiable);

        $title = (string) ($payload['title'] ?? '');
        $body = (string) ($payload['body'] ?? '');
        $data = (array) ($payload['data'] ?? []);

        $tokens = $notifiable->fcmTokens()->pluck('token')->all();

        if ($tokens === []) {
            return;
        }

        $message = CloudMessage::new()
            ->withNotification(FcmNotification::create($title, $body))
            ->withData(array_map('strval', $data));

        $this->messaging->sendMulticast($message, $tokens);
    }
}
