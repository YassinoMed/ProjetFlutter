<?php

namespace App\Events;

use App\Models\Message;
use App\Models\MessageReceipt;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ConversationMessageReceiptUpdated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly Message $message,
        public readonly MessageReceipt $receipt,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('conversations.'.$this->message->conversation_id);
    }

    public function broadcastAs(): string
    {
        return 'message.receipt.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'message_id' => $this->message->id,
            'conversation_id' => $this->message->conversation_id,
            'user_id' => $this->receipt->user_id,
            'status' => $this->receipt->status?->value ?? $this->receipt->status,
            'status_at_utc' => optional($this->receipt->status_at_utc)?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
