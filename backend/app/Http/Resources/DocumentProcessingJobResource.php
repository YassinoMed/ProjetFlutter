<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DocumentProcessingJobResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'job_type' => $this->job_type,
            'job_label' => $this->jobLabel(),
            'queue_name' => $this->queue_name,
            'attempt' => $this->attempt,
            'status' => $this->status?->value ?? $this->status,
            'started_at_utc' => $this->started_at_utc?->setTimezone('UTC')?->toISOString(),
            'completed_at_utc' => $this->completed_at_utc?->setTimezone('UTC')?->toISOString(),
            'failed_at_utc' => $this->failed_at_utc?->setTimezone('UTC')?->toISOString(),
            'error_code' => $this->error_code,
            'error_message_sanitized' => $this->error_message_sanitized,
            'meta' => $this->meta,
            'created_at_utc' => $this->created_at?->setTimezone('UTC')?->toISOString(),
            'updated_at_utc' => $this->updated_at?->setTimezone('UTC')?->toISOString(),
        ];
    }

    private function jobLabel(): string
    {
        return match (class_basename((string) $this->job_type)) {
            'ProcessDocumentJob' => 'Analyse du document',
            default => 'Traitement documentaire',
        };
    }
}
