<?php

namespace App\Services\Chat;

use App\Enums\ChatMessageStatus;
use App\Events\ChatMessageAcknowledged;
use App\Events\ChatMessageSent;
use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Models\ChatMessageStatusEntry;
use App\Models\User;
use App\Notifications\ChatMessageNotification;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ChatMessageService
{
    public function sendMessage(Appointment $consultation, User $sender, array $payload): ChatMessage
    {
        $recipientId = $consultation->patient_user_id === $sender->id
            ? $consultation->doctor_user_id
            : $consultation->patient_user_id;

        if ($recipientId === null || $recipientId === $sender->id) {
            throw ValidationException::withMessages([
                'recipient' => ['Invalid recipient'],
            ]);
        }

        return DB::transaction(function () use ($consultation, $sender, $recipientId, $payload): ChatMessage {
            $message = ChatMessage::query()->create([
                'consultation_id' => $consultation->id,
                'sender_user_id' => $sender->id,
                'recipient_user_id' => $recipientId,
                'ciphertext' => $payload['ciphertext'],
                'nonce' => $payload['nonce'],
                'algorithm' => $payload['algorithm'],
                'key_id' => $payload['key_id'] ?? null,
                'metadata_encrypted' => $payload['metadata_encrypted'] ?? null,
                'sent_at_utc' => now('UTC'),
            ]);

            ChatMessageStatusEntry::query()->create([
                'message_id' => $message->id,
                'user_id' => $sender->id,
                'status' => ChatMessageStatus::SENT,
                'status_at_utc' => now('UTC'),
            ]);

            DB::afterCommit(function () use ($message, $recipientId): void {
                $message = $message->load(['statuses' => fn ($q) => $q->orderByDesc('status_at_utc')]);

                event(new ChatMessageSent($message));

                $recipient = User::query()->find($recipientId);

                if ($recipient !== null) {
                    $recipient->notify(new ChatMessageNotification($message));
                }
            });

            return $message;
        });
    }

    public function acknowledge(ChatMessage $message, User $user, string $status): ChatMessageStatusEntry
    {
        return DB::transaction(function () use ($message, $user, $status): ChatMessageStatusEntry {
            $entry = ChatMessageStatusEntry::query()
                ->where('message_id', $message->id)
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if ($entry !== null && $entry->status === ChatMessageStatus::READ) {
                return $entry;
            }

            if ($entry !== null && $entry->status === ChatMessageStatus::DELIVERED && $status === ChatMessageStatus::DELIVERED->value) {
                return $entry;
            }

            $entry = ChatMessageStatusEntry::query()->updateOrCreate(
                [
                    'message_id' => $message->id,
                    'user_id' => $user->id,
                ],
                [
                    'status' => $status,
                    'status_at_utc' => now('UTC'),
                ],
            );

            DB::afterCommit(function () use ($message, $user, $entry): void {
                event(new ChatMessageAcknowledged(
                    $message,
                    $user->id,
                    $entry->status->value,
                    $entry->status_at_utc->setTimezone('UTC')->toISOString(),
                ));
            });

            return $entry;
        });
    }
}
