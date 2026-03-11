<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DocumentExtractionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'version' => $this->version,
            'status' => $this->status?->value ?? $this->status,
            'source' => $this->source,
            'engine' => $this->engine,
            'language_code' => $this->language_code,
            'raw_text' => $this->raw_text_encrypted,
            'normalized_text' => $this->normalized_text_encrypted,
            'structured_payload' => $this->structured_payload,
            'missing_sections' => $this->missing_sections,
            'confidence_score' => $this->confidence_score,
            'started_at_utc' => $this->started_at_utc?->setTimezone('UTC')?->toISOString(),
            'completed_at_utc' => $this->completed_at_utc?->setTimezone('UTC')?->toISOString(),
            'failed_at_utc' => $this->failed_at_utc?->setTimezone('UTC')?->toISOString(),
            'error_code' => $this->error_code,
            'error_message_sanitized' => $this->error_message_sanitized,
        ];
    }
}
