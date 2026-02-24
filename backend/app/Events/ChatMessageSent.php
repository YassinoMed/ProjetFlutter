<?php

namespace App\Events;

use App\Http\Resources\ChatMessageResource;
use App\Models\ChatMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatMessageSent implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public readonly ChatMessage $message) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('consultations.'.$this->message->consultation_id);
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'CHAT_MESSAGE',
            'message' => (new ChatMessageResource($this->message))->resolve(),
        ];
    }
}
