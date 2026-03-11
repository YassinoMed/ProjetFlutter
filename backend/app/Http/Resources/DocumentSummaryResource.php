<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DocumentSummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'version' => $this->version,
            'status' => $this->status?->value ?? $this->status,
            'audience' => $this->audience?->value ?? $this->audience,
            'format' => $this->format?->value ?? $this->format,
            'summary_text' => $this->summary_text_encrypted,
            'structured_payload' => $this->structured_payload,
            'factual_basis' => $this->factual_basis,
            'missing_fields' => $this->missing_fields,
            'confidence_score' => $this->confidence_score,
            'generated_at_utc' => $this->generated_at_utc?->setTimezone('UTC')?->toISOString(),
        ];
    }
}
