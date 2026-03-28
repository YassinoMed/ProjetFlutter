<?php

namespace App\Events;

use App\Http\Resources\TeleconsultationResource;
use App\Models\Teleconsultation;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TeleconsultationUpdated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public readonly Teleconsultation $teleconsultation) {}

    public function broadcastOn(): array
    {
        $channels = [
            new PrivateChannel('teleconsultations.'.$this->teleconsultation->id),
        ];

        if ($this->teleconsultation->conversation_id !== null) {
            $channels[] = new PrivateChannel('conversations.'.$this->teleconsultation->conversation_id);
        }

        return $channels;
    }

    public function broadcastAs(): string
    {
        return 'teleconsultation.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'teleconsultation' => (new TeleconsultationResource($this->teleconsultation))->resolve(),
        ];
    }
}
