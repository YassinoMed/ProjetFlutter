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
            'confirmed' => '✅ Rendez-vous confirmé',
            'cancelled' => '❌ Rendez-vous annulé',
            'reminder_j1' => '🔔 Rappel rendez-vous (J-1)',
            'reminder_h1' => '⏰ Rappel rendez-vous (H-1)',
            default => '📋 Mise à jour rendez-vous',
        };

        $body = match ($this->event) {
            'confirmed' => sprintf(
                'Votre rendez-vous du %s a été confirmé.',
                optional($this->appointment->starts_at_utc)?->format('d/m/Y à H:i') ?? '—'
            ),
            'cancelled' => 'Votre rendez-vous a été annulé. Vous pouvez en reprogrammer un.',
            'reminder_j1' => sprintf(
                'Rappel : vous avez un rendez-vous demain à %s.',
                optional($this->appointment->starts_at_utc)?->format('H:i') ?? '—'
            ),
            'reminder_h1' => sprintf(
                'Rappel : votre rendez-vous commence dans 1 heure (%s).',
                optional($this->appointment->starts_at_utc)?->format('H:i') ?? '—'
            ),
            default => 'Le statut de votre rendez-vous a changé.',
        };

        // Rich Push: action buttons
        $actions = match ($this->event) {
            'confirmed' => [
                ['id' => 'view', 'title' => 'Voir le RDV', 'action' => 'VIEW_APPOINTMENT'],
                ['id' => 'reschedule', 'title' => 'Reprogrammer', 'action' => 'RESCHEDULE'],
            ],
            'cancelled' => [
                ['id' => 'rebook', 'title' => 'Nouveau RDV', 'action' => 'NEW_APPOINTMENT'],
            ],
            'reminder_j1', 'reminder_h1' => [
                ['id' => 'view', 'title' => 'Voir le RDV', 'action' => 'VIEW_APPOINTMENT'],
                ['id' => 'cancel', 'title' => 'Annuler', 'action' => 'CANCEL_APPOINTMENT', 'destructive' => true],
            ],
            default => [],
        };

        return [
            'title' => $title,
            'body' => $body,
            'image' => null, // Can point to doctor's avatar URL in the future
            'category' => 'APPOINTMENT_ACTIONS',
            'priority' => in_array($this->event, ['reminder_h1', 'confirmed']) ? 'high' : 'normal',
            'badge' => 1,
            'actions' => $actions,
            'data' => [
                'type' => 'APPOINTMENT',
                'event' => $this->event,
                'appointment_id' => $this->appointment->id,
                'starts_at_utc' => optional($this->appointment->starts_at_utc)?->setTimezone('UTC')?->toISOString(),
                'status' => $this->appointment->status?->value ?? (string) $this->appointment->status,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'deep_link' => '/appointments/' . $this->appointment->id,
            ],
        ];
    }
}
