<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DocumentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'patient_user_id' => $this->patient_user_id,
            'doctor_user_id' => $this->doctor_user_id,
            'uploaded_by_user_id' => $this->uploaded_by_user_id,
            'original_filename' => $this->original_filename,
            'mime_type' => $this->mime_type,
            'file_extension' => $this->file_extension,
            'file_size_bytes' => $this->file_size_bytes,
            'document_type' => $this->document_type?->value ?? $this->document_type,
            'processing_status' => $this->processing_status?->value ?? $this->processing_status,
            'extraction_status' => $this->extraction_status?->value ?? $this->extraction_status,
            'summary_status' => $this->summary_status?->value ?? $this->summary_status,
            'ocr_required' => $this->ocr_required,
            'ocr_used' => $this->ocr_used,
            'urgency_level' => $this->urgency_level?->value ?? $this->urgency_level,
            'language_code' => $this->language_code,
            'classification_confidence' => $this->classification_confidence,
            'document_date_utc' => $this->document_date_utc?->setTimezone('UTC')?->toISOString(),
            'processed_at_utc' => $this->processed_at_utc?->setTimezone('UTC')?->toISOString(),
            'failed_at_utc' => $this->failed_at_utc?->setTimezone('UTC')?->toISOString(),
            'last_error_code' => $this->last_error_code,
            'last_error_message_sanitized' => $this->last_error_message_sanitized,
            'source_metadata' => $this->source_metadata,
            'processing_pipeline' => $this->processingPipeline(),
            'tags' => $this->whenLoaded('tags', fn () => $this->tags->map(
                fn ($tag) => [
                    'tag' => $tag->tag,
                    'confidence_score' => $tag->confidence_score,
                ]
            )->values()->all()),
            'latest_extraction' => $this->whenLoaded('latestExtraction', function () {
                if ($this->latestExtraction === null) {
                    return null;
                }

                return new DocumentExtractionResource($this->latestExtraction);
            }),
            'summaries' => $this->whenLoaded('summaries', fn () => DocumentSummaryResource::collection($this->summaries)),
            'entities' => $this->whenLoaded('entities', fn () => DocumentEntityResource::collection($this->entities)),
            'processing_jobs' => $this->whenLoaded(
                'processingJobs',
                fn () => DocumentProcessingJobResource::collection($this->processingJobs)
            ),
            'created_at_utc' => $this->created_at?->setTimezone('UTC')?->toISOString(),
            'updated_at_utc' => $this->updated_at?->setTimezone('UTC')?->toISOString(),
        ];
    }

    private function processingPipeline(): array
    {
        return [
            'overall_status' => $this->processing_status?->value ?? $this->processing_status,
            'ocr_required' => (bool) $this->ocr_required,
            'ocr_used' => (bool) $this->ocr_used,
            'processed_at_utc' => $this->processed_at_utc?->setTimezone('UTC')?->toISOString(),
            'failed_at_utc' => $this->failed_at_utc?->setTimezone('UTC')?->toISOString(),
            'stages' => [
                [
                    'stage' => 'UPLOAD',
                    'label' => 'Document recu',
                    'status' => 'COMPLETED',
                ],
                [
                    'stage' => 'EXTRACTION',
                    'label' => 'Extraction du texte',
                    'status' => $this->extraction_status?->value ?? $this->extraction_status,
                ],
                [
                    'stage' => 'SUMMARY',
                    'label' => 'Analyse et resume IA',
                    'status' => $this->summary_status?->value ?? $this->summary_status,
                ],
            ],
        ];
    }
}
