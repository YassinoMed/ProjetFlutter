<?php

namespace App\Notifications;

use App\Models\Appointment;
use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class AppointmentStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly Appointment $appointment,
        private readonly string $event,
    ) {}

    public function via(User $notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm(User $notifiable): array
    {
        $title = match ($this->event) {
            'confirmed' => 'Rendez-vous confirmé',
            'cancelled' => 'Rendez-vous annulé',
            'reminder_j1' => 'Rappel rendez-vous (J-1)',
            'reminder_h1' => 'Rappel rendez-vous (H-1)',
            default => 'Mise à jour rendez-vous',
        };

        $body = match ($this->event) {
            'confirmed' => 'Votre rendez-vous a été confirmé.',
            'cancelled' => 'Votre rendez-vous a été annulé.',
            'reminder_j1' => 'Vous avez un rendez-vous demain.',
            'reminder_h1' => 'Vous avez un rendez-vous dans 1 heure.',
            default => 'Le statut de votre rendez-vous a changé.',
        };

        return [
            'title' => $title,
            'body' => $body,
            'data' => [
                'type' => 'APPOINTMENT',
                'event' => $this->event,
                'appointment_id' => $this->appointment->id,
                'starts_at_utc' => optional($this->appointment->starts_at_utc)?->setTimezone('UTC')?->toISOString(),
                'status' => $this->appointment->status?->value ?? (string) $this->appointment->status,
            ],
        ];
    }
}
