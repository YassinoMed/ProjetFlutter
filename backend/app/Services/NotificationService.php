<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Models\User;
use App\Notifications\AppointmentStatusNotification;
use App\Notifications\ChatMessageNotification;
use App\Notifications\IncomingCallNotification;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Notify about appointment status changes.
     * CDC p.17: "appointment_booked", "appointment_confirmed", "appointment_cancelled", "appointment_reminder"
     */
    public function notifyAppointmentStatusChange(Appointment $appointment, string $event): void
    {
        try {
            $patient = User::query()->find($appointment->patient_user_id);
            $doctor = User::query()->find($appointment->doctor_user_id);

            if ($patient !== null) {
                $patient->notify(new AppointmentStatusNotification($appointment, $event, 'patient'));
            }

            if ($doctor !== null) {
                $doctor->notify(new AppointmentStatusNotification($appointment, $event, 'doctor'));
            }

            Log::channel('security')->info('notification_sent', [
                'event' => "appointment_{$event}",
                'appointment_id' => $appointment->id,
            ]);
        } catch (\Throwable $e) {
            Log::error('NotificationService::notifyAppointmentStatusChange failed', [
                'appointment_id' => $appointment->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Notify about new chat message.
     * CDC p.17: "new_message"
     */
    public function notifyChatMessage(ChatMessage $message): void
    {
        try {
            $recipient = User::query()->find($message->recipient_user_id);

            if ($recipient !== null) {
                $recipient->notify(new ChatMessageNotification($message));
            }
        } catch (\Throwable $e) {
            Log::error('NotificationService::notifyChatMessage failed', [
                'message_id' => $message->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Notify about incoming call.
     * CDC p.18: "incoming_call"
     */
    public function notifyIncomingCall(string $appointmentId, User $caller, string $recipientUserId, string $callType = 'video'): void
    {
        try {
            $recipient = User::query()->find($recipientUserId);

            if ($recipient !== null) {
                $recipient->notify(new IncomingCallNotification($appointmentId, $caller, $callType));
            }

            Log::channel('security')->info('notification_sent', [
                'event' => 'incoming_call',
                'appointment_id' => $appointmentId,
                'caller_id' => $caller->id,
                'recipient_id' => $recipientUserId,
            ]);
        } catch (\Throwable $e) {
            Log::error('NotificationService::notifyIncomingCall failed', [
                'appointment_id' => $appointmentId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Notify about appointment reminder (scheduled job).
     * CDC p.17: "appointment_reminder" 24h / 1h before
     */
    public function notifyAppointmentReminder(Appointment $appointment, string $type = '24h'): void
    {
        try {
            $patient = User::query()->find($appointment->patient_user_id);
            $doctor = User::query()->find($appointment->doctor_user_id);

            if ($patient !== null) {
                $patient->notify(new AppointmentStatusNotification($appointment, "reminder_{$type}", 'patient'));
            }

            if ($doctor !== null) {
                $doctor->notify(new AppointmentStatusNotification($appointment, "reminder_{$type}", 'doctor'));
            }
        } catch (\Throwable $e) {
            Log::error('NotificationService::notifyAppointmentReminder failed', [
                'appointment_id' => $appointment->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
