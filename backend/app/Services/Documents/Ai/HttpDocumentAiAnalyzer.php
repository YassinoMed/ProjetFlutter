<?php

namespace App\Services\Documents\Ai;

use App\Enums\DocumentSummaryAudience;
use App\Enums\DocumentSummaryFormat;
use App\Enums\DocumentType;
use App\Enums\DocumentUrgency;
use App\Models\Document;
use App\Services\Documents\Contracts\DocumentAiAnalyzer;
use App\Services\Documents\Data\DocumentAnalysisResult;
use App\Services\Documents\Data\TextExtractionResult;
use App\Services\Documents\Prompts\DocumentPromptFactory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Throwable;

class HttpDocumentAiAnalyzer implements DocumentAiAnalyzer
{
    public function __construct(
        private readonly HeuristicDocumentAiAnalyzer $fallback,
        private readonly DocumentPromptFactory $prompts,
    ) {}

    public function analyze(Document $document, TextExtractionResult $extraction): DocumentAnalysisResult
    {
        $fallbackResult = $this->fallback->analyze($document, $extraction);

        if (! $this->isConfigured()) {
            return $fallbackResult;
        }

        try {
            $payload = $this->callProvider($extraction);

            if ($payload === null) {
                return $fallbackResult;
            }

            return $this->buildResult($payload, $fallbackResult, $extraction);
        } catch (Throwable) {
            return $fallbackResult;
        }
    }

    private function isConfigured(): bool
    {
        return trim((string) config('documents.ai.base_url')) !== ''
            && trim((string) config('documents.ai.api_key')) !== ''
            && trim((string) config('documents.ai.model')) !== '';
    }

    private function callProvider(TextExtractionResult $extraction): ?array
    {
        $response = Http::timeout((int) config('documents.ai_timeout_seconds', 45))
            ->acceptJson()
            ->withToken((string) config('documents.ai.api_key'))
            ->post((string) config('documents.ai.base_url'), [
                'model' => (string) config('documents.ai.model'),
                'temperature' => 0,
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => $this->prompts->extractionPrompt(),
                    ],
                    [
                        'role' => 'user',
                        'content' => "Analyse le texte OCR suivant sans inventer d'information.\n\n".Str::limit($extraction->normalizedText, 12000, ''),
                    ],
                ],
            ]);

        if (! $response->successful()) {
            return null;
        }

        $json = $response->json();
        $content = data_get($json, 'choices.0.message.content')
            ?? data_get($json, 'analysis')
            ?? data_get($json, 'output')
            ?? $json;

        if (is_string($content)) {
            $decoded = json_decode($content, true);

            return is_array($decoded) ? $decoded : null;
        }

        return is_array($content) ? $content : null;
    }

    private function buildResult(
        array $payload,
        DocumentAnalysisResult $fallback,
        TextExtractionResult $extraction,
    ): DocumentAnalysisResult {
        $fields = $this->normalizeFields($payload, $fallback->structuredFields);
        $documentType = DocumentType::tryFrom((string) ($payload['document_type'] ?? '')) ?? $fallback->documentType;
        $urgency = DocumentUrgency::tryFrom((string) ($payload['urgency_level'] ?? '')) ?? $fallback->urgency;
        $missing = $this->stringList($payload['missing_fields'] ?? $fallback->missingInformation);
        $warnings = $this->stringList($payload['uncertainty_notes'] ?? []);
        $facts = $this->stringList($payload['facts_only'] ?? []);

        if ($facts === []) {
            $facts = $this->factsFromFields($fields, $documentType, $urgency);
        }

        return new DocumentAnalysisResult(
            documentType: $documentType,
            urgency: $urgency,
            classificationConfidence: $this->confidence($payload, $fallback),
            structuredFields: $fields,
            entities: $this->entitiesFromFields($fields),
            summaries: $this->summaries($fields, $documentType, $urgency, $facts, $missing, $warnings),
            tags: $this->tags($payload, $documentType, $fields),
            warnings: $warnings,
            missingInformation: $missing,
            languageCode: $extraction->languageCode ?? $fallback->languageCode ?? 'fr',
        );
    }

    private function normalizeFields(array $payload, array $fallbackFields): array
    {
        return [
            'patient_name' => $this->nullableString($payload['patient_name'] ?? $fallbackFields['patient_name'] ?? null),
            'document_date' => $this->nullableString($payload['document_date'] ?? $fallbackFields['document_date'] ?? null),
            'doctor_name' => $this->nullableString($payload['doctor_name'] ?? $fallbackFields['doctor_name'] ?? null),
            'establishment' => $this->nullableString($payload['establishment'] ?? $fallbackFields['establishment'] ?? null),
            'specialty' => $this->nullableString($payload['specialty'] ?? $fallbackFields['specialty'] ?? null),
            'diagnosis' => $this->nullableString($payload['diagnosis'] ?? $fallbackFields['diagnosis'] ?? null),
            'suspected_diagnosis' => $this->nullableString($payload['suspected_diagnosis'] ?? $fallbackFields['suspected_diagnosis'] ?? null),
            'symptoms' => $this->stringList($payload['symptoms'] ?? $fallbackFields['symptoms'] ?? []),
            'medical_history' => $this->stringList($payload['medical_history'] ?? $fallbackFields['medical_history'] ?? []),
            'treatments' => $this->stringList($payload['treatments'] ?? $fallbackFields['treatments'] ?? []),
            'requested_exams' => $this->stringList($payload['requested_exams'] ?? $fallbackFields['requested_exams'] ?? []),
            'important_lab_results' => $this->stringList($payload['important_lab_results'] ?? $fallbackFields['important_lab_results'] ?? []),
            'recommendations' => $this->stringList($payload['recommendations'] ?? $fallbackFields['recommendations'] ?? []),
            'follow_up_date' => $this->nullableString($payload['follow_up_date'] ?? $fallbackFields['follow_up_date'] ?? null),
            'interpretation_candidates' => $this->stringList($payload['interpretation_candidates'] ?? []),
        ];
    }

    private function summaries(
        array $fields,
        ?DocumentType $documentType,
        DocumentUrgency $urgency,
        array $facts,
        array $missing,
        array $warnings,
    ): array {
        $diagnosis = $fields['diagnosis'] ?? $fields['suspected_diagnosis'] ?? null;
        $documentTypeValue = $documentType instanceof DocumentType ? $documentType->value : 'OTHER';

        return [
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::SHORT->value,
                'summary_text' => $facts === [] ? 'Aucun fait exploitable extrait du document.' : implode(' ', array_slice($facts, 0, 4)),
                'structured_payload' => null,
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.86,
            ],
            [
                'audience' => DocumentSummaryAudience::PATIENT->value,
                'format' => DocumentSummaryFormat::PATIENT_FRIENDLY->value,
                'summary_text' => implode(' ', array_values(array_filter([
                    'Ce document semble correspondre à: '.$documentTypeValue.'.',
                    $diagnosis ? 'Il mentionne: '.$diagnosis.'.' : 'Aucun diagnostic clair n’a été extrait.',
                    ! empty($fields['treatments']) ? 'Traitements cités: '.implode('; ', $fields['treatments']).'.' : null,
                    $warnings !== [] ? 'Certains éléments restent incertains: '.implode('; ', $warnings).'.' : null,
                    'Ce résumé ne remplace pas l’avis médical.',
                ]))),
                'structured_payload' => [
                    'document_type' => $documentTypeValue,
                    'urgency' => $urgency->value,
                ],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.82,
            ],
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::STRUCTURED->value,
                'summary_text' => implode("\n", array_values(array_filter([
                    'Type: '.$documentTypeValue,
                    'Urgence: '.$urgency->value,
                    'Diagnostic / hypothèse: '.($diagnosis ?? 'Non mentionné'),
                    ! empty($fields['treatments']) ? 'Traitements: '.implode('; ', $fields['treatments']) : null,
                    ! empty($fields['important_lab_results']) ? 'Résultats importants: '.implode('; ', $fields['important_lab_results']) : null,
                    ! empty($fields['recommendations']) ? 'Recommandations: '.implode('; ', $fields['recommendations']) : null,
                    'Résumé fondé uniquement sur les faits extraits.',
                ]))),
                'structured_payload' => [
                    'document_type' => $documentTypeValue,
                    'urgency' => $urgency->value,
                    'facts' => $facts,
                    'warnings' => $warnings,
                    'missing_fields' => $missing,
                ],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.84,
            ],
        ];
    }

    private function entitiesFromFields(array $fields): array
    {
        $entities = [];

        foreach ($fields as $type => $value) {
            if ($value === null || $value === []) {
                continue;
            }

            foreach (is_array($value) ? $value : [$value] as $entry) {
                if (! is_string($entry) || trim($entry) === '') {
                    continue;
                }

                $entities[] = [
                    'entity_type' => $type,
                    'label' => str($type)->replace('_', ' ')->title()->toString(),
                    'value' => $entry,
                    'confidence_score' => 0.84,
                    'is_sensitive' => true,
                    'qualifiers' => [],
                ];
            }
        }

        return $entities;
    }

    private function tags(array $payload, ?DocumentType $documentType, array $fields): array
    {
        $tags = [];

        if ($documentType !== null) {
            $tags[] = ['tag' => $documentType->value, 'confidence_score' => 0.9];
        }

        foreach ($this->stringList($payload['keywords'] ?? []) as $keyword) {
            $tags[] = [
                'tag' => str($keyword)->upper()->limit(40, '')->toString(),
                'confidence_score' => 0.78,
            ];
        }

        if (! empty($fields['treatments'])) {
            $tags[] = ['tag' => 'TRAITEMENT', 'confidence_score' => 0.82];
        }

        return collect($tags)->unique('tag')->values()->all();
    }

    private function factsFromFields(array $fields, ?DocumentType $documentType, DocumentUrgency $urgency): array
    {
        $documentTypeValue = $documentType instanceof DocumentType ? $documentType->value : 'OTHER';

        return array_values(array_filter([
            'Type détecté: '.$documentTypeValue.'.',
            'Niveau d’urgence estimé: '.$urgency->value.'.',
            $fields['diagnosis'] ? 'Diagnostic mentionné: '.$fields['diagnosis'].'.' : null,
            $fields['suspected_diagnosis'] ? 'Hypothèse mentionnée: '.$fields['suspected_diagnosis'].'.' : null,
            ! empty($fields['treatments']) ? 'Traitements cités: '.implode('; ', $fields['treatments']).'.' : null,
            ! empty($fields['recommendations']) ? 'Recommandations: '.implode('; ', $fields['recommendations']).'.' : null,
        ]));
    }

    private function nullableString(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_scalar($value)) {
            return trim((string) $value) ?: null;
        }

        return null;
    }

    private function stringList(mixed $value): array
    {
        if (is_string($value)) {
            return trim($value) === '' ? [] : [trim($value)];
        }

        if (! is_array($value)) {
            return [];
        }

        return collect($value)
            ->map(fn (mixed $entry) => $this->stringifyEntry($entry))
            ->filter(fn (?string $entry) => $entry !== null && trim($entry) !== '')
            ->values()
            ->all();
    }

    private function stringifyEntry(mixed $entry): ?string
    {
        if (is_scalar($entry)) {
            return trim((string) $entry) ?: null;
        }

        if (! is_array($entry)) {
            return null;
        }

        $parts = collect($entry)
            ->filter(fn (mixed $value) => is_scalar($value) && trim((string) $value) !== '')
            ->map(fn (mixed $value, string|int $key) => is_string($key) ? $key.': '.$value : (string) $value)
            ->values()
            ->all();

        return $parts === [] ? null : implode(', ', $parts);
    }

    private function confidence(array $payload, DocumentAnalysisResult $fallback): float
    {
        $value = $payload['confidence'] ?? $payload['classification_confidence'] ?? $fallback->classificationConfidence;

        return max(0.0, min((float) $value, 1.0));
    }
}
