<?php

namespace App\Services\Messages;

use App\Enums\MessageReceiptStatus;
use App\Events\ConversationMessageCreated;
use App\Events\ConversationMessageReceiptUpdated;
use App\Events\ConversationTypingUpdated;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\MessageReceipt;
use App\Models\User;
use App\Notifications\SecureMessageNotification;
use App\Services\AuditService;
use App\Services\Conversations\ConversationService;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;

class MessageService
{
    public function __construct(
        private readonly ConversationService $conversationService,
        private readonly AuditService $auditService,
    ) {}

    public function send(User $sender, array $payload): Message
    {
        /** @var Conversation $conversation */
        $conversation = Conversation::query()
            ->with('participants.user')
            ->findOrFail($payload['conversation_id']);

        $this->conversationService->assertParticipant($conversation, $sender);

        return DB::transaction(function () use ($conversation, $sender, $payload): Message {
            $sentAt = isset($payload['sent_at_utc'])
                ? CarbonImmutable::parse($payload['sent_at_utc'])->utc()
                : now('UTC');

            $message = Message::query()->create([
                'conversation_id' => $conversation->id,
                'sender_user_id' => $sender->id,
                'client_message_id' => $payload['client_message_id'] ?? null,
                'message_type' => $payload['message_type'],
                'ciphertext' => $payload['ciphertext'],
                'nonce' => $payload['nonce'],
                'e2ee_version' => $payload['e2ee_version'],
                'sender_key_id' => $payload['sender_key_id'] ?? null,
                'server_metadata' => $payload['server_metadata'] ?? null,
                'sent_at_utc' => $sentAt,
                'expires_at' => now('UTC')->addDays(config('mediconnect.message_retention_days', 730)),
            ]);

            foreach ($conversation->participants as $participant) {
                MessageReceipt::query()->create([
                    'message_id' => $message->id,
                    'user_id' => $participant->user_id,
                    'status' => $participant->user_id === $sender->id
                        ? MessageReceiptStatus::SENT->value
                        : MessageReceiptStatus::SENT->value,
                    'status_at_utc' => now('UTC'),
                ]);
            }

            $conversation->forceFill([
                'last_message_at_utc' => $message->sent_at_utc,
            ])->save();

            $conversation->participants()
                ->where('user_id', $sender->id)
                ->update(['last_seen_at_utc' => now('UTC')]);

            $this->auditService->log($sender, 'message.sent', $message, [
                'conversation_id' => $conversation->id,
                'message_type' => $message->message_type?->value ?? $message->message_type,
            ]);

            DB::afterCommit(function () use ($message, $conversation, $sender): void {
                $message = $message->load('receipts');

                event(new ConversationMessageCreated($message));

                $conversation->participants
                    ->where('user_id', '!=', $sender->id)
                    ->each(function ($participant) use ($message): void {
                        $participant->user?->notify(new SecureMessageNotification($message));
                    });
            });

            return $message->load('receipts');
        });
    }

    public function updateReceipt(Message $message, User $user, MessageReceiptStatus $status): MessageReceipt
    {
        $conversation = $message->conversation()->firstOrFail();
        $this->conversationService->assertParticipant($conversation, $user);

        if ($message->sender_user_id === $user->id) {
            throw new AuthorizationException('The sender cannot update delivered/read receipts on the same message.');
        }

        return DB::transaction(function () use ($message, $conversation, $user, $status): MessageReceipt {
            $receipt = MessageReceipt::query()
                ->where('message_id', $message->id)
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($this->rank($receipt->status) >= $this->rank($status)) {
                return $receipt;
            }

            $receipt->forceFill([
                'status' => $status,
                'status_at_utc' => now('UTC'),
            ])->save();

            $participantUpdates = ['last_seen_at_utc' => now('UTC')];

            if ($status === MessageReceiptStatus::DELIVERED) {
                $participantUpdates['last_delivered_at_utc'] = now('UTC');
            }

            if ($status === MessageReceiptStatus::READ) {
                $participantUpdates['last_read_at_utc'] = now('UTC');
                $participantUpdates['last_delivered_at_utc'] = now('UTC');
            }

            $conversation->participants()
                ->where('user_id', $user->id)
                ->update($participantUpdates);

            $this->auditService->log($user, 'message.receipt.updated', $message, [
                'status' => $status->value,
            ]);

            DB::afterCommit(function () use ($message, $receipt): void {
                event(new ConversationMessageReceiptUpdated($message, $receipt));
            });

            return $receipt;
        });
    }

    public function broadcastTyping(Conversation $conversation, User $user, bool $isTyping): void
    {
        $this->conversationService->assertParticipant($conversation, $user);
        $this->conversationService->touchPresence($conversation, $user);

        event(new ConversationTypingUpdated(
            $conversation->id,
            $user->id,
            $isTyping,
            now('UTC')->toISOString(),
        ));
    }

    private function rank(MessageReceiptStatus $status): int
    {
        return match ($status) {
            MessageReceiptStatus::SENT => 1,
            MessageReceiptStatus::DELIVERED => 2,
            MessageReceiptStatus::READ => 3,
        };
    }
}
