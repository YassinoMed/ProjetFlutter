<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ConversationTypingUpdated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly string $conversationId,
        public readonly string $userId,
        public readonly bool $isTyping,
        public readonly string $timestampUtc,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('conversations.'.$this->conversationId);
    }

    public function broadcastAs(): string
    {
        return 'conversation.typing';
    }

    public function broadcastWith(): array
    {
        return [
            'conversation_id' => $this->conversationId,
            'user_id' => $this->userId,
            'is_typing' => $this->isTyping,
            'timestamp_utc' => $this->timestampUtc,
        ];
    }
}
