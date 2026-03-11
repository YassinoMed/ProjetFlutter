<?php

namespace App\Services\Documents;

use App\Enums\DocumentProcessingStatus;
use App\Models\Document;
use App\Models\DocumentEntity;
use App\Models\DocumentExtraction;
use App\Models\DocumentSummary;
use App\Models\DocumentTag;
use App\Services\AuditService;
use App\Services\Documents\Contracts\DocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Throwable;

class DocumentAnalysisPipeline
{
    public function __construct(
        private readonly DocumentTextExtractor $textExtractor,
        private readonly DocumentAiAnalyzer $aiAnalyzer,
        private readonly AuditService $auditService,
    ) {}

    public function process(Document $document): Document
    {
        $document->forceFill([
            'processing_status' => DocumentProcessingStatus::PROCESSING->value,
            'extraction_status' => DocumentProcessingStatus::PROCESSING->value,
            'summary_status' => DocumentProcessingStatus::PROCESSING->value,
            'last_error_code' => null,
            'last_error_message_sanitized' => null,
            'failed_at_utc' => null,
        ])->save();

        $version = ((int) $document->extractions()->max('version')) + 1;

        /** @var DocumentExtraction $extraction */
        $extraction = $document->extractions()->create([
            'version' => $version,
            'status' => DocumentProcessingStatus::PROCESSING->value,
            'started_at_utc' => now('UTC'),
        ]);

        try {
            $extracted = $this->textExtractor->extract($document);

            if (trim($extracted->normalizedText) === '') {
                throw new \RuntimeException('No readable text was extracted from the document.');
            }

            $analysis = $this->aiAnalyzer->analyze($document, $extracted);

            DB::transaction(function () use ($document, $extraction, $version, $extracted, $analysis): void {
                $extraction->forceFill([
                    'status' => DocumentProcessingStatus::COMPLETED->value,
                    'source' => $extracted->source,
                    'engine' => $extracted->engine,
                    'language_code' => $analysis->languageCode ?? $extracted->languageCode,
                    'raw_text_encrypted' => $extracted->rawText,
                    'normalized_text_encrypted' => $extracted->normalizedText,
                    'structured_payload' => $analysis->structuredFields,
                    'missing_sections' => $analysis->missingInformation,
                    'confidence_score' => $extracted->confidenceScore,
                    'completed_at_utc' => now('UTC'),
                    'meta' => $extracted->meta,
                ])->save();

                foreach ($analysis->entities as $entity) {
                    DocumentEntity::query()->create([
                        'document_id' => $document->id,
                        'version' => $version,
                        'entity_type' => $entity['entity_type'],
                        'label' => $entity['label'],
                        'value_encrypted' => $entity['value'],
                        'is_sensitive' => $entity['is_sensitive'] ?? true,
                        'confidence_score' => $entity['confidence_score'] ?? null,
                        'qualifiers' => $entity['qualifiers'] ?? [],
                    ]);
                }

                foreach ($analysis->summaries as $summary) {
                    DocumentSummary::query()->create([
                        'document_id' => $document->id,
                        'version' => $version,
                        'status' => DocumentProcessingStatus::COMPLETED->value,
                        'audience' => $summary['audience'],
                        'format' => $summary['format'],
                        'summary_text_encrypted' => $summary['summary_text'],
                        'structured_payload' => $summary['structured_payload'] ?? null,
                        'factual_basis' => $summary['factual_basis'] ?? null,
                        'missing_fields' => $summary['missing_fields'] ?? null,
                        'confidence_score' => $summary['confidence_score'] ?? null,
                        'generated_at_utc' => now('UTC'),
                    ]);
                }

                foreach ($analysis->tags as $tag) {
                    DocumentTag::query()->updateOrCreate(
                        [
                            'document_id' => $document->id,
                            'tag' => $tag['tag'],
                        ],
                        [
                            'confidence_score' => $tag['confidence_score'] ?? null,
                        ],
                    );
                }

                $document->forceFill([
                    'document_type' => $analysis->documentType?->value,
                    'urgency_level' => $analysis->urgency->value,
                    'classification_confidence' => $analysis->classificationConfidence,
                    'processing_status' => DocumentProcessingStatus::COMPLETED->value,
                    'extraction_status' => DocumentProcessingStatus::COMPLETED->value,
                    'summary_status' => DocumentProcessingStatus::COMPLETED->value,
                    'ocr_required' => $extracted->ocrRequired,
                    'ocr_used' => $extracted->ocrUsed,
                    'language_code' => $analysis->languageCode ?? $extracted->languageCode,
                    'document_date_utc' => $this->parsePossibleDate($analysis->structuredFields['document_date'] ?? null),
                    'processed_at_utc' => now('UTC'),
                    'source_metadata' => [
                        'warnings' => $analysis->warnings,
                        'missing_information' => $analysis->missingInformation,
                    ],
                ])->save();
            });

            $this->auditService->log(
                $document->uploadedBy,
                'document.analysis.completed',
                $document,
                [
                    'document_type' => $document->document_type?->value ?? $document->document_type,
                    'status' => DocumentProcessingStatus::COMPLETED->value,
                ],
            );
        } catch (Throwable $exception) {
            $sanitizedMessage = $this->sanitizeException($exception->getMessage());

            $extraction->forceFill([
                'status' => DocumentProcessingStatus::FAILED->value,
                'failed_at_utc' => now('UTC'),
                'error_code' => class_basename($exception),
                'error_message_sanitized' => $sanitizedMessage,
            ])->save();

            $document->forceFill([
                'processing_status' => DocumentProcessingStatus::FAILED->value,
                'extraction_status' => DocumentProcessingStatus::FAILED->value,
                'summary_status' => DocumentProcessingStatus::FAILED->value,
                'failed_at_utc' => now('UTC'),
                'last_error_code' => class_basename($exception),
                'last_error_message_sanitized' => $sanitizedMessage,
            ])->save();

            $this->auditService->log(
                $document->uploadedBy,
                'document.analysis.failed',
                $document,
                [
                    'error_code' => class_basename($exception),
                    'error_message' => $sanitizedMessage,
                ],
            );

            throw $exception;
        }

        return $document->fresh(['latestExtraction', 'summaries', 'entities', 'tags']);
    }

    private function parsePossibleDate(?string $value): ?Carbon
    {
        if ($value === null || trim($value) === '') {
            return null;
        }

        try {
            return Carbon::parse($value, 'UTC');
        } catch (Throwable) {
            return null;
        }
    }

    private function sanitizeException(string $message): string
    {
        return str($message)->limit(240)->replaceMatches('/[\r\n\t]+/', ' ')->toString();
    }
}
