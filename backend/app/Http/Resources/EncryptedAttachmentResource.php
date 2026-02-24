<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EncryptedAttachmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'owner_user_id' => $this->owner_user_id,
            'original_filename' => $this->original_filename,
            'mime_type' => $this->mime_type,
            'file_size_bytes' => $this->file_size_bytes,
            'algorithm' => $this->algorithm,
            'nonce' => $this->nonce,
            'key_id' => $this->key_id,
            'encrypted_key' => $this->encrypted_key,
            'checksum_sha256' => $this->checksum_sha256,
            'attachable_type' => $this->attachable_type ? class_basename($this->attachable_type) : null,
            'attachable_id' => $this->attachable_id,
            'expires_at' => $this->expires_at?->setTimezone('UTC')->toISOString(),
            'created_at' => $this->created_at?->setTimezone('UTC')->toISOString(),
        ];
    }
}
