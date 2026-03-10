<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class WebRtcIceCandidateRelayed implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly string $callSessionId,
        public readonly ?string $conversationId,
        public readonly string $actorUserId,
        public readonly string $targetUserId,
        public readonly array $candidate,
        public readonly string $timestampUtc,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('calls.'.$this->callSessionId);
    }

    public function broadcastAs(): string
    {
        return 'webrtc.ice_candidate';
    }

    public function broadcastWith(): array
    {
        return [
            'call_session_id' => $this->callSessionId,
            'conversation_id' => $this->conversationId,
            'actor_user_id' => $this->actorUserId,
            'target_user_id' => $this->targetUserId,
            'candidate' => $this->candidate,
            'timestamp_utc' => $this->timestampUtc,
        ];
    }
}
