<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class WebRtcAnswerSent implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly string $consultationId,
        public readonly string $userId,
        public readonly string $sdp,
        public readonly string $sdpType,
        public readonly string $sentAtUtc,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('consultations.'.$this->consultationId);
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'WEBRTC_ANSWER',
            'consultation_id' => $this->consultationId,
            'user_id' => $this->userId,
            'sdp' => $this->sdp,
            'sdp_type' => $this->sdpType,
            'sent_at_utc' => $this->sentAtUtc,
        ];
    }
}
