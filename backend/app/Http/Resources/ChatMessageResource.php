<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatMessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $userId = $request->user()?->id;

        $status = 'SENT';

        if ($userId !== null && $this->relationLoaded('statuses')) {
            if ($this->sender_user_id === $userId) {
                $statusEntry = $this->statuses
                    ->where('user_id', '!=', $userId)
                    ->sortByDesc('status_at_utc')
                    ->first();

                $status = $statusEntry?->status?->value ?? 'SENT';
            } else {
                $statusEntry = $this->statuses
                    ->where('user_id', $userId)
                    ->sortByDesc('status_at_utc')
                    ->first();

                $status = $statusEntry?->status?->value ?? 'SENT';
            }
        }

        return [
            'id' => $this->id,
            'consultation_id' => $this->consultation_id,
            'sender_user_id' => $this->sender_user_id,
            'recipient_user_id' => $this->recipient_user_id,
            'is_me' => $userId !== null ? $this->sender_user_id === $userId : null,
            'ciphertext' => $this->ciphertext,
            'nonce' => $this->nonce,
            'algorithm' => $this->algorithm,
            'key_id' => $this->key_id,
            'metadata_encrypted' => $this->metadata_encrypted,
            'sent_at_utc' => optional($this->sent_at_utc)->setTimezone('UTC')?->toISOString(),
            'status' => $status,
        ];
    }
}
