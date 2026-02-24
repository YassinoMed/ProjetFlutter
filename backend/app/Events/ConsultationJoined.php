<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ConsultationJoined implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly string $consultationId,
        public readonly string $userId,
        public readonly string $joinedAtUtc,
    ) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('consultations.'.$this->consultationId);
    }

    public function broadcastWith(): array
    {
        return [
            'type' => 'JOIN_CONSULTATION',
            'consultation_id' => $this->consultationId,
            'user_id' => $this->userId,
            'joined_at_utc' => $this->joinedAtUtc,
        ];
    }
}
