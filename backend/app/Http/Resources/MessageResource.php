<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'sender_user_id' => $this->sender_user_id,
            'client_message_id' => $this->client_message_id,
            'message_type' => $this->message_type?->value ?? $this->message_type,
            'ciphertext' => $this->ciphertext,
            'nonce' => $this->nonce,
            'e2ee_version' => $this->e2ee_version,
            'sender_key_id' => $this->sender_key_id,
            'server_metadata' => $this->server_metadata,
            'sent_at_utc' => optional($this->sent_at_utc)?->setTimezone('UTC')?->toISOString(),
            'server_received_at_utc' => optional($this->server_received_at_utc)?->setTimezone('UTC')?->toISOString(),
            'receipts' => $this->whenLoaded('receipts', fn () => $this->receipts->map(fn ($receipt) => [
                'user_id' => $receipt->user_id,
                'status' => $receipt->status?->value ?? $receipt->status,
                'status_at_utc' => optional($receipt->status_at_utc)?->setTimezone('UTC')?->toISOString(),
            ])->values()->all()),
        ];
    }
}
