<?php

namespace App\Notifications;

use App\Models\Teleconsultation;
use App\Models\User;
use App\Notifications\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class TeleconsultationReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly Teleconsultation $teleconsultation,
        private readonly string $window,
    ) {}

    public function via(User $notifiable): array
    {
        return [FcmChannel::class];
    }

    public function toFcm(User $notifiable): array
    {
        $isDoctor = $notifiable->id === $this->teleconsultation->doctor_user_id;
        $counterpart = $isDoctor
            ? trim(($this->teleconsultation->patient?->first_name ?? '').' '.($this->teleconsultation->patient?->last_name ?? ''))
            : 'Dr. '.trim(($this->teleconsultation->doctor?->first_name ?? '').' '.($this->teleconsultation->doctor?->last_name ?? ''));

        $formattedStart = optional($this->teleconsultation->scheduled_starts_at_utc)?->format('d/m/Y à H:i') ?? '—';

        $title = match ($this->window) {
            '24h' => 'Rappel téléconsultation demain',
            '1h' => 'Téléconsultation dans 1 heure',
            default => 'Rappel téléconsultation',
        };

        $body = match ($this->window) {
            '24h' => $isDoctor
                ? sprintf('Rappel: votre téléconsultation avec %s est prévue demain à %s.', $counterpart, $formattedStart)
                : sprintf('Rappel: votre téléconsultation avec %s est prévue demain à %s.', $counterpart, $formattedStart),
            '1h' => $isDoctor
                ? sprintf('Votre téléconsultation avec %s commence dans 1 heure (%s).', $counterpart, $formattedStart)
                : sprintf('Votre téléconsultation avec %s commence dans 1 heure (%s).', $counterpart, $formattedStart),
            default => sprintf('Votre téléconsultation avec %s est prévue à %s.', $counterpart, $formattedStart),
        };

        return [
            'title' => $title,
            'body' => $body,
            'category' => 'APPOINTMENT_ACTIONS',
            'priority' => $this->window === '1h' ? 'high' : 'normal',
            'actions' => [
                ['id' => 'view', 'title' => 'Voir la session', 'action' => 'VIEW_TELECONSULTATION'],
            ],
            'data' => [
                'type' => 'APPOINTMENT',
                'event' => 'teleconsultation_reminder_'.$this->window,
                'teleconsultation_id' => $this->teleconsultation->id,
                'appointment_id' => $this->teleconsultation->appointment_id,
                'call_type' => $this->teleconsultation->call_type?->value ?? $this->teleconsultation->call_type,
                'doctor_name' => trim(($this->teleconsultation->doctor?->first_name ?? '').' '.($this->teleconsultation->doctor?->last_name ?? '')),
                'patient_name' => trim(($this->teleconsultation->patient?->first_name ?? '').' '.($this->teleconsultation->patient?->last_name ?? '')),
                'starts_at_utc' => optional($this->teleconsultation->scheduled_starts_at_utc)?->setTimezone('UTC')?->toISOString(),
                'deep_link' => '/teleconsultations/'.$this->teleconsultation->id,
            ],
        ];
    }
}
