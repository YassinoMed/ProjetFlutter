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

class HeuristicDocumentAiAnalyzer implements DocumentAiAnalyzer
{
    public function analyze(Document $document, TextExtractionResult $extraction): DocumentAnalysisResult
    {
        $text = trim($extraction->normalizedText);
        $lower = mb_strtolower($text);

        $documentType = $this->detectType($lower);
        $urgency = $this->detectUrgency($lower);
        $fields = $this->extractStructuredFields($text);
        $entities = $this->buildEntities($fields);
        $tags = $this->buildTags($documentType, $lower, $fields);
        $missing = $this->missingFields($fields);
        $warnings = [];

        if ($fields['document_date'] === null) {
            $warnings[] = 'Date du document non trouvée.';
        }

        return new DocumentAnalysisResult(
            documentType: $documentType,
            urgency: $urgency,
            classificationConfidence: $documentType === DocumentType::OTHER ? 0.45 : 0.82,
            structuredFields: $fields,
            entities: $entities,
            summaries: $this->buildSummaries($fields, $documentType, $urgency, $missing),
            tags: $tags,
            warnings: $warnings,
            missingInformation: $missing,
            languageCode: $extraction->languageCode ?? 'fr',
        );
    }

    private function detectType(string $text): DocumentType
    {
        return match (true) {
            str_contains($text, 'ordonnance'), str_contains($text, 'prescription') => DocumentType::PRESCRIPTION,
            str_contains($text, 'analyse biologique'), str_contains($text, 'laboratoire'), preg_match('/\b(hba1c|glyc[ée]mie|crp|h[ée]moglobine)\b/u', $text) === 1 => DocumentType::LAB_RESULT,
            str_contains($text, 'radiologie'), str_contains($text, 'irm'), str_contains($text, 'scanner'), str_contains($text, 'radiographie') => DocumentType::RADIOLOGY_REPORT,
            str_contains($text, 'certificat'), str_contains($text, 'arrêt de travail') => DocumentType::MEDICAL_CERTIFICATE,
            str_contains($text, 'orientation'), str_contains($text, 'adressé'), str_contains($text, 'lettre') => DocumentType::REFERRAL_LETTER,
            str_contains($text, 'historique de consultation'), str_contains($text, 'consultation antérieure') => DocumentType::CONSULTATION_HISTORY,
            str_contains($text, 'compte rendu'), str_contains($text, 'observation') => DocumentType::MEDICAL_REPORT,
            default => DocumentType::OTHER,
        };
    }

    private function detectUrgency(string $text): DocumentUrgency
    {
        return match (true) {
            preg_match('/\b(urgence vitale|critique|imm[ée]diat|hospitalisation urgente)\b/u', $text) === 1 => DocumentUrgency::CRITICAL,
            preg_match('/\b(urgent|sans d[ée]lai|surveillance rapproch[ée]e)\b/u', $text) === 1 => DocumentUrgency::HIGH,
            preg_match('/\b([àa] contr[ôo]ler|surveillance|suivi recommand[ée])\b/u', $text) === 1 => DocumentUrgency::MEDIUM,
            $text !== '' => DocumentUrgency::LOW,
            default => DocumentUrgency::UNKNOWN,
        };
    }

    private function extractStructuredFields(string $text): array
    {
        return [
            'patient_name' => $this->matchOne($text, [
                '/(?:patient|nom du patient)\s*[:\-]\s*([^\n\r]+)/iu',
            ]),
            'document_date' => $this->matchOne($text, [
                '/(?:date|fait le)\s*[:\-]?\s*((?:\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})|(?:\d{4}-\d{2}-\d{2}))/iu',
            ]),
            'doctor_name' => $this->matchOne($text, [
                '/(?:dr|docteur)\s+([A-ZÀ-ÿ][^\n\r,]+)/u',
                '/(?:m[ée]decin)\s*[:\-]\s*([^\n\r]+)/iu',
            ]),
            'establishment' => $this->matchOne($text, [
                '/(?:h[ôo]pital|clinique|cabinet|centre)\s*[:\-]?\s*([^\n\r]+)/iu',
            ]),
            'specialty' => $this->matchOne($text, [
                '/(?:sp[ée]cialit[ée]|service)\s*[:\-]\s*([^\n\r]+)/iu',
            ]),
            'diagnosis' => $this->matchOne($text, [
                '/(?:diagnostic)\s*[:\-]\s*([^\n\r]+)/iu',
            ]),
            'suspected_diagnosis' => $this->matchOne($text, [
                '/(?:suspicion diagnostique|hypoth[èe]se)\s*[:\-]\s*([^\n\r]+)/iu',
            ]),
            'symptoms' => $this->matchMany($text, '/(?:sympt[ôo]mes?)\s*[:\-]\s*([^\n\r]+)/iu'),
            'medical_history' => $this->matchMany($text, '/(?:ant[ée]c[ée]dents?)\s*[:\-]\s*([^\n\r]+)/iu'),
            'treatments' => $this->matchMany($text, '/(?:traitement|prescription|m[ée]dicament[s]?)\s*[:\-]\s*([^\n\r]+)/iu'),
            'requested_exams' => $this->matchMany($text, '/(?:examens? demand[ée]s?|bilan demand[ée])\s*[:\-]\s*([^\n\r]+)/iu'),
            'important_lab_results' => $this->matchMany($text, '/(?:r[ée]sultats? importants?|anomalies?)\s*[:\-]\s*([^\n\r]+)/iu'),
            'recommendations' => $this->matchMany($text, '/(?:recommandations?|conduite [àa] tenir)\s*[:\-]\s*([^\n\r]+)/iu'),
            'follow_up_date' => $this->matchOne($text, [
                '/(?:prochain rendez-vous|suivi|contr[ôo]le)\s*[:\-]?\s*([^\n\r]+)/iu',
            ]),
        ];
    }

    private function buildEntities(array $fields): array
    {
        $entities = [];

        foreach ($fields as $type => $value) {
            if ($value === null || $value === []) {
                continue;
            }

            if (is_array($value)) {
                foreach ($value as $entry) {
                    $entities[] = [
                        'entity_type' => $type,
                        'label' => $this->labelFor($type),
                        'value' => $entry,
                        'confidence_score' => 0.72,
                        'is_sensitive' => true,
                        'qualifiers' => [],
                    ];
                }

                continue;
            }

            $entities[] = [
                'entity_type' => $type,
                'label' => $this->labelFor($type),
                'value' => $value,
                'confidence_score' => 0.78,
                'is_sensitive' => true,
                'qualifiers' => [],
            ];
        }

        return $entities;
    }

    private function buildSummaries(array $fields, ?DocumentType $documentType, DocumentUrgency $urgency, array $missing): array
    {
        $facts = $this->factLines($fields, $documentType, $urgency);
        $shortSummary = implode(' ', array_slice($facts, 0, 3));
        $criticalAlerts = $this->criticalSummaryText($fields, $urgency);

        return [
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::SHORT->value,
                'summary_text' => trim($shortSummary) !== '' ? $shortSummary : 'Aucun fait exploitable extrait du document.',
                'structured_payload' => null,
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.79,
            ],
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::STRUCTURED->value,
                'summary_text' => $this->structuredSummaryText($fields, $documentType, $urgency),
                'structured_payload' => [
                    'document_type' => $documentType?->value ?? 'OTHER',
                    'urgency' => $urgency->value,
                    'facts' => $facts,
                    'missing_fields' => $missing,
                ],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.81,
            ],
            [
                'audience' => DocumentSummaryAudience::PATIENT->value,
                'format' => DocumentSummaryFormat::PATIENT_FRIENDLY->value,
                'summary_text' => $this->patientSummaryText($fields, $documentType, $urgency),
                'structured_payload' => [
                    'document_type' => $documentType?->value ?? 'OTHER',
                    'urgency' => $urgency->value,
                ],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.77,
            ],
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::PROFESSIONAL_DETAILED->value,
                'summary_text' => $this->professionalDetailedSummaryText($fields, $documentType, $urgency, $missing),
                'structured_payload' => [
                    'sections' => [
                        'diagnosis' => $fields['diagnosis'] ?? $fields['suspected_diagnosis'],
                        'symptoms' => $fields['symptoms'] ?? [],
                        'medical_history' => $fields['medical_history'] ?? [],
                        'treatments' => $fields['treatments'] ?? [],
                        'requested_exams' => $fields['requested_exams'] ?? [],
                        'important_lab_results' => $fields['important_lab_results'] ?? [],
                        'follow_up_date' => $fields['follow_up_date'] ?? null,
                    ],
                ],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.83,
            ],
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::BULLETS->value,
                'summary_text' => implode("\n", array_map(static fn ($line) => '- '.$line, $facts)),
                'structured_payload' => ['bullets' => $facts],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.8,
            ],
            [
                'audience' => DocumentSummaryAudience::PROFESSIONAL->value,
                'format' => DocumentSummaryFormat::CRITICAL->value,
                'summary_text' => $criticalAlerts,
                'structured_payload' => ['urgency' => $urgency->value, 'alerts' => [$criticalAlerts]],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.7,
            ],
            [
                'audience' => DocumentSummaryAudience::ADMINISTRATIVE->value,
                'format' => DocumentSummaryFormat::ADMINISTRATIVE->value,
                'summary_text' => $this->administrativeSummaryText($fields, $documentType),
                'structured_payload' => [
                    'patient_name' => $fields['patient_name'] ?? null,
                    'doctor_name' => $fields['doctor_name'] ?? null,
                    'document_date' => $fields['document_date'] ?? null,
                    'follow_up_date' => $fields['follow_up_date'] ?? null,
                ],
                'factual_basis' => $facts,
                'missing_fields' => $missing,
                'confidence_score' => 0.76,
            ],
        ];
    }

    private function buildTags(?DocumentType $documentType, string $text, array $fields): array
    {
        $tags = [];

        if ($documentType !== null) {
            $tags[] = ['tag' => $documentType->value, 'confidence_score' => 0.9];
        }

        foreach (['diabète', 'hypertension', 'cardio', 'grossesse', 'infection', 'allergie'] as $keyword) {
            if (str_contains($text, $keyword)) {
                $tags[] = ['tag' => mb_strtoupper($keyword), 'confidence_score' => 0.68];
            }
        }

        if (! empty($fields['treatments'])) {
            $tags[] = ['tag' => 'TRAITEMENT', 'confidence_score' => 0.72];
        }

        if (! empty($fields['important_lab_results'])) {
            $tags[] = ['tag' => 'RESULTATS_IMPORTANTS', 'confidence_score' => 0.75];
        }

        return collect($tags)->unique('tag')->values()->all();
    }

    private function missingFields(array $fields): array
    {
        $missing = [];

        foreach (['document_date', 'patient_name', 'doctor_name', 'diagnosis', 'treatments'] as $field) {
            $value = $fields[$field] ?? null;
            if ($value === null || $value === []) {
                $missing[] = $field;
            }
        }

        return $missing;
    }

    private function factLines(array $fields, ?DocumentType $documentType, DocumentUrgency $urgency): array
    {
        $lines = [];

        $lines[] = 'Type détecté: '.($documentType?->value ?? 'OTHER').'.';
        $lines[] = 'Niveau d’urgence estimé: '.$urgency->value.'.';

        if ($fields['diagnosis'] !== null) {
            $lines[] = 'Diagnostic mentionné: '.$fields['diagnosis'].'.';
        } elseif ($fields['suspected_diagnosis'] !== null) {
            $lines[] = 'Suspicion diagnostique mentionnée: '.$fields['suspected_diagnosis'].'.';
        }

        if (! empty($fields['treatments'])) {
            $lines[] = 'Traitements cités: '.implode('; ', $fields['treatments']).'.';
        }

        if (! empty($fields['recommendations'])) {
            $lines[] = 'Recommandations: '.implode('; ', $fields['recommendations']).'.';
        }

        return array_values(array_filter($lines));
    }

    private function structuredSummaryText(array $fields, ?DocumentType $documentType, DocumentUrgency $urgency): string
    {
        return implode("\n", [
            'Type: '.($documentType?->value ?? 'OTHER'),
            'Urgence: '.$urgency->value,
            'Patient: '.($fields['patient_name'] ?? 'Non mentionné'),
            'Date: '.($fields['document_date'] ?? 'Non mentionnée'),
            'Diagnostic: '.($fields['diagnosis'] ?? $fields['suspected_diagnosis'] ?? 'Non mentionné'),
            'Traitements: '.(! empty($fields['treatments']) ? implode('; ', $fields['treatments']) : 'Non mentionnés'),
            'Examens demandés: '.(! empty($fields['requested_exams']) ? implode('; ', $fields['requested_exams']) : 'Non mentionnés'),
            'Suivi: '.($fields['follow_up_date'] ?? 'Non mentionné'),
            'Avertissement: résumé généré uniquement à partir des faits détectés dans le document.',
        ]);
    }

    private function patientSummaryText(array $fields, ?DocumentType $documentType, DocumentUrgency $urgency): string
    {
        return implode(' ', array_values(array_filter([
            'Ce document semble correspondre à: '.($documentType?->value ?? 'OTHER').'.',
            $fields['diagnosis'] ? 'Le document mentionne: '.$fields['diagnosis'].'.' : null,
            ! empty($fields['treatments']) ? 'Un traitement est cité: '.implode('; ', $fields['treatments']).'.' : 'Aucun traitement clair n’a été détecté.',
            $fields['follow_up_date'] ? 'Un suivi est mentionné: '.$fields['follow_up_date'].'.' : 'Aucune date de suivi claire n’a été trouvée.',
            'Niveau d’urgence détecté: '.$urgency->value.'.',
            'Ce résumé ne remplace pas l’avis du médecin.',
        ])));
    }

    private function professionalDetailedSummaryText(
        array $fields,
        ?DocumentType $documentType,
        DocumentUrgency $urgency,
        array $missing,
    ): string {
        return implode("\n", array_values(array_filter([
            'Type documentaire: '.($documentType?->value ?? 'OTHER'),
            'Niveau d’urgence détecté: '.$urgency->value,
            'Diagnostic / hypothèse: '.($fields['diagnosis'] ?? $fields['suspected_diagnosis'] ?? 'Non documenté'),
            ! empty($fields['symptoms']) ? 'Symptômes: '.implode('; ', $fields['symptoms']) : null,
            ! empty($fields['medical_history']) ? 'Antécédents: '.implode('; ', $fields['medical_history']) : null,
            ! empty($fields['treatments']) ? 'Traitements / prescription: '.implode('; ', $fields['treatments']) : null,
            ! empty($fields['important_lab_results']) ? 'Résultats biologiques importants: '.implode('; ', $fields['important_lab_results']) : null,
            ! empty($fields['requested_exams']) ? 'Examens demandés: '.implode('; ', $fields['requested_exams']) : null,
            ! empty($fields['recommendations']) ? 'Recommandations: '.implode('; ', $fields['recommendations']) : null,
            $fields['follow_up_date'] ? 'Suivi / prochain rendez-vous: '.$fields['follow_up_date'] : null,
            $missing !== [] ? 'Champs potentiellement manquants: '.implode(', ', $missing) : null,
            'Résumé fondé uniquement sur les éléments explicitement détectés dans le document.',
        ])));
    }

    private function criticalSummaryText(array $fields, DocumentUrgency $urgency): string
    {
        if ($urgency === DocumentUrgency::CRITICAL || $urgency === DocumentUrgency::HIGH) {
            return 'Surveillance prioritaire recommandée selon les termes présents dans le document.';
        }

        if (! empty($fields['important_lab_results'])) {
            return 'Des résultats biologiques ou anomalies importantes sont mentionnés.';
        }

        return 'Aucun élément critique explicite détecté dans le document.';
    }

    private function administrativeSummaryText(array $fields, ?DocumentType $documentType): string
    {
        return implode("\n", [
            'Type: '.($documentType?->value ?? 'OTHER'),
            'Patient: '.($fields['patient_name'] ?? 'Non mentionné'),
            'Date document: '.($fields['document_date'] ?? 'Non mentionnée'),
            'Médecin / émetteur: '.($fields['doctor_name'] ?? $fields['establishment'] ?? 'Non mentionné'),
            'Spécialité: '.($fields['specialty'] ?? 'Non mentionnée'),
            'Suivi: '.($fields['follow_up_date'] ?? 'Non mentionné'),
            'Résumé administratif limité aux éléments factuels du document.',
        ]);
    }

    private function matchOne(string $text, array $patterns): ?string
    {
        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $text, $matches) === 1) {
                return trim($matches[1]);
            }
        }

        return null;
    }

    private function matchMany(string $text, string $pattern): array
    {
        if (preg_match_all($pattern, $text, $matches) !== false && ! empty($matches[1])) {
            return array_values(array_filter(array_map(static fn ($value) => trim($value), $matches[1])));
        }

        return [];
    }

    private function labelFor(string $type): string
    {
        return match ($type) {
            'patient_name' => 'Nom du patient',
            'document_date' => 'Date du document',
            'doctor_name' => 'Nom du médecin',
            'establishment' => 'Établissement',
            'specialty' => 'Spécialité',
            'diagnosis' => 'Diagnostic',
            'suspected_diagnosis' => 'Suspicion diagnostique',
            'symptoms' => 'Symptômes',
            'medical_history' => 'Antécédents',
            'treatments' => 'Traitements',
            'requested_exams' => 'Examens demandés',
            'important_lab_results' => 'Résultats biologiques importants',
            'recommendations' => 'Recommandations',
            'follow_up_date' => 'Date de suivi',
            default => $type,
        };
    }
}
