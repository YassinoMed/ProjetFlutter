<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class WebRtcIceCandidateSent implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly string $consultationId,
        public readonly string $userId,
        public readonly string $candidate,
        public readonly ?string $sdpMid,
        public readonly ?int $sdpMLineIndex,
        public readonly string $sentAtUtc,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('consultations.'.$this->consultationId);
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'ICE_CANDIDATE',
            'consultation_id' => $this->consultationId,
            'user_id' => $this->userId,
            'candidate' => $this->candidate,
            'sdp_mid' => $this->sdpMid,
            'sdp_mline_index' => $this->sdpMLineIndex,
            'sent_at_utc' => $this->sentAtUtc,
        ];
    }
}
