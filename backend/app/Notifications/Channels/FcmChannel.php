<?php

namespace App\Notifications\Channels;

use App\Models\User;
use Illuminate\Notifications\Notification;
use Kreait\Firebase\Messaging;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
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
        $imageUrl = $payload['image'] ?? null;
        $actions = $payload['actions'] ?? [];
        $category = $payload['category'] ?? null;
        $priority = $payload['priority'] ?? 'high';
        $badge = $payload['badge'] ?? null;

        $tokens = $notifiable->fcmTokens()->pluck('token')->all();

        if ($tokens === []) {
            return;
        }

        // ── Core notification ────────────────────────────
        $fcmNotification = FcmNotification::create($title, $body);
        if ($imageUrl) {
            $fcmNotification = $fcmNotification->withImageUrl($imageUrl);
        }

        // ── Rich Android config ──────────────────────────
        $androidConfig = AndroidConfig::fromArray([
            'priority' => $priority,
            'notification' => array_filter([
                'channel_id' => $this->resolveAndroidChannel($data['type'] ?? 'default'),
                'icon' => 'ic_notification',
                'color' => '#0D6EFD',
                'sound' => 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'image' => $imageUrl,
                'notification_count' => $badge,
            ]),
        ]);

        // ── Rich iOS (APNs) config ───────────────────────
        $apnsPayload = [
            'aps' => array_filter([
                'alert' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'sound' => 'default',
                'badge' => $badge,
                'mutable-content' => 1,         // Required for Notification Service Extension (image)
                'category' => $category,         // Required for action buttons
                'content-available' => 1,
                'interruption-level' => $this->resolveInterruptionLevel($data['type'] ?? 'default'),
            ]),
        ];

        // Attach image URL for iOS Notification Service Extension
        if ($imageUrl) {
            $apnsPayload['fcm_options'] = ['image' => $imageUrl];
        }

        // Add action buttons metadata to APNs
        if (! empty($actions)) {
            $apnsPayload['aps']['category'] = $category ?? 'RICH_ACTIONS';
            $data['actions'] = json_encode($actions);
        }

        $apnsConfig = ApnsConfig::fromArray([
            'payload' => $apnsPayload,
            'headers' => [
                'apns-priority' => $priority === 'high' ? '10' : '5',
                'apns-push-type' => 'alert',
            ],
        ]);

        // ── Build and send ───────────────────────────────
        $message = CloudMessage::new()
            ->withNotification($fcmNotification)
            ->withData(array_map('strval', $data))
            ->withAndroidConfig($androidConfig)
            ->withApnsConfig($apnsConfig);

        $this->messaging->sendMulticast($message, $tokens);
    }

    /**
     * Map notification type → Android notification channel.
     */
    private function resolveAndroidChannel(string $type): string
    {
        return match ($type) {
            'APPOINTMENT' => 'appointments',
            'CHAT' => 'messages',
            'CALL' => 'calls',
            'MEDICAL_RECORD' => 'medical_records',
            default => 'general',
        };
    }

    /**
     * Map notification type → iOS interruption level.
     */
    private function resolveInterruptionLevel(string $type): string
    {
        return match ($type) {
            'CALL' => 'time-sensitive',
            'APPOINTMENT' => 'time-sensitive',
            'CHAT' => 'active',
            default => 'active',
        };
    }
}
