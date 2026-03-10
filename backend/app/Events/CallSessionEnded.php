<?php

namespace App\Events;

use App\Http\Resources\CallSessionResource;
use App\Models\CallSession;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CallSessionEnded implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public readonly CallSession $callSession) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('calls.'.$this->callSession->id),
            new PrivateChannel('conversations.'.$this->callSession->conversation_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'webrtc.ended';
    }

    public function broadcastWith(): array
    {
        return [
            'call_session' => (new CallSessionResource($this->callSession))->resolve(),
        ];
    }
}
