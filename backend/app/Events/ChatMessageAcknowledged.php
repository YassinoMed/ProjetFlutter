<?php

namespace App\Events;

use App\Models\ChatMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatMessageAcknowledged implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly ChatMessage $message,
        public readonly string $userId,
        public readonly string $status,
        public readonly string $statusAtUtc,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('consultations.'.$this->message->consultation_id);
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'CHAT_ACK',
            'message_id' => $this->message->id,
            'user_id' => $this->userId,
            'status' => $this->status,
            'status_at_utc' => $this->statusAtUtc,
        ];
    }
}
