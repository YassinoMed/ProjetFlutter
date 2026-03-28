<?php

namespace App\Jobs;

use App\Enums\DocumentProcessingStatus;
use App\Models\Document;
use App\Models\DocumentProcessingJob;
use App\Services\Documents\DocumentAnalysisPipeline;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class ProcessDocumentJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries = 2;

    public function __construct(private readonly string $documentId) {}

    public function handle(DocumentAnalysisPipeline $pipeline): void
    {
        $document = Document::query()->find($this->documentId);

        if ($document === null) {
            return;
        }

        $jobRecord = DocumentProcessingJob::query()->create([
            'document_id' => $document->id,
            'job_type' => self::class,
            'queue_name' => $this->queue,
            'attempt' => $this->attempts(),
            'status' => DocumentProcessingStatus::PROCESSING->value,
            'started_at_utc' => now('UTC'),
        ]);

        try {
            $pipeline->process($document);

            $jobRecord->forceFill([
                'status' => DocumentProcessingStatus::COMPLETED->value,
                'completed_at_utc' => now('UTC'),
                'meta' => [
                    'document_processing_status' => $document->fresh()?->processing_status?->value ?? null,
                ],
            ])->save();
        } catch (Throwable $exception) {
            $jobRecord->forceFill([
                'status' => DocumentProcessingStatus::FAILED->value,
                'failed_at_utc' => now('UTC'),
                'error_code' => class_basename($exception),
                'error_message_sanitized' => str($exception->getMessage())->limit(240)->replaceMatches('/[\r\n\t]+/', ' ')->toString(),
            ])->save();

            throw $exception;
        }
    }
}
