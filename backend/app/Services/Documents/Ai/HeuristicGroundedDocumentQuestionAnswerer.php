<?php

namespace App\Services\Documents\Ai;

use App\Enums\DocumentSummaryAudience;
use App\Models\Document;
use App\Services\Documents\Contracts\DocumentQuestionAnswerer;
use App\Services\Documents\Data\DocumentQuestionAnswerResult;

class HeuristicGroundedDocumentQuestionAnswerer implements DocumentQuestionAnswerer
{
    private const FIELD_KEYWORDS = [
        'patient_name' => ['patient', 'nom'],
        'document_date' => ['date', 'quand'],
        'doctor_name' => ['medecin', 'médecin', 'docteur', 'dr'],
        'establishment' => ['clinique', 'hopital', 'hôpital', 'cabinet', 'centre', 'etablissement', 'établissement'],
        'specialty' => ['specialite', 'spécialité', 'service'],
        'diagnosis' => ['diagnostic'],
        'suspected_diagnosis' => ['hypothese', 'hypothèse', 'suspicion'],
        'symptoms' => ['symptome', 'symptômes', 'symptomes'],
        'medical_history' => ['antecedent', 'antécédent', 'antecedents', 'antécédents', 'historique'],
        'treatments' => ['traitement', 'traitements', 'medicament', 'médicament', 'ordonnance', 'prescrit', 'posologie', 'dose'],
        'requested_exams' => ['examen', 'examens', 'bilan', 'analyse', 'scanner', 'irm', 'radio'],
        'important_lab_results' => ['resultat', 'résultat', 'biologie', 'analyse', 'lab', 'glycemie', 'glycémie', 'crp', 'hba1c'],
        'recommendations' => ['recommandation', 'conseil', 'surveillance', 'conduite'],
        'follow_up_date' => ['suivi', 'controle', 'contrôle', 'rendez-vous', 'prochain'],
    ];

    public function answer(Document $document, string $question, DocumentSummaryAudience $audience): DocumentQuestionAnswerResult
    {
        $question = trim($question);
        $extraction = $document->latestExtraction;

        if ($question === '' || $extraction === null) {
            return $this->insufficientEvidenceResult($question, $audience, [
                'Le document n’a pas encore de texte exploitable pour répondre.',
            ]);
        }

        $normalizedText = trim((string) ($extraction->normalized_text_encrypted ?? ''));
        $structuredFields = is_array($extraction->structured_payload) ? $extraction->structured_payload : [];
        $matchedFields = $this->matchStructuredFields($question, $structuredFields);
        $uncertaintyNotes = [];

        if (($extraction->confidence_score ?? 1) < 0.75) {
            $uncertaintyNotes[] = 'Le niveau de confiance OCR/extraction est partiel; vérifier le document source.';
        }

        if (! empty($extraction->missing_sections)) {
            $uncertaintyNotes[] = 'Certaines sections utiles semblent absentes ou non détectées: '.implode(', ', $extraction->missing_sections).'.';
        }

        if ($matchedFields !== []) {
            $evidence = [];
            $answers = [];

            foreach ($matchedFields as $field) {
                $value = $structuredFields[$field] ?? null;

                if ($value === null || $value === [] || $value === '') {
                    continue;
                }

                $excerpt = is_array($value) ? implode('; ', array_map('strval', $value)) : (string) $value;
                $answers[] = $this->formatFieldAnswer($field, $excerpt, $audience);
                $evidence[] = [
                    'source' => 'structured_field',
                    'field' => $field,
                    'excerpt' => $excerpt,
                    'certainty' => 'HIGH',
                ];
            }

            if ($answers !== []) {
                return new DocumentQuestionAnswerResult(
                    question: $question,
                    audience: $audience,
                    answer: $this->composeAudienceAnswer($audience, $answers),
                    insufficientEvidence: false,
                    evidence: $evidence,
                    uncertaintyNotes: $uncertaintyNotes,
                    usedStructuredFields: $matchedFields,
                    confidenceScore: $this->confidenceFromEvidence(count($evidence), true),
                );
            }
        }

        $evidenceLines = $this->findRelevantLines($question, $normalizedText);

        if ($evidenceLines === []) {
            return $this->insufficientEvidenceResult($question, $audience, array_merge($uncertaintyNotes, [
                'Le document ne contient pas assez d’éléments explicites pour répondre à cette question.',
            ]));
        }

        return new DocumentQuestionAnswerResult(
            question: $question,
            audience: $audience,
            answer: $this->composeTextEvidenceAnswer($audience, $evidenceLines),
            insufficientEvidence: false,
            evidence: array_map(static fn (string $line) => [
                'source' => 'document_text',
                'field' => null,
                'excerpt' => $line,
                'certainty' => 'MEDIUM',
            ], $evidenceLines),
            uncertaintyNotes: array_merge($uncertaintyNotes, [
                'Réponse formulée à partir d’extraits textuels, sans interprétation clinique supplémentaire.',
            ]),
            usedStructuredFields: [],
            confidenceScore: $this->confidenceFromEvidence(count($evidenceLines), false),
        );
    }

    private function insufficientEvidenceResult(
        string $question,
        DocumentSummaryAudience $audience,
        array $notes,
    ): DocumentQuestionAnswerResult {
        $answer = match ($audience) {
            DocumentSummaryAudience::PATIENT => 'Je ne peux pas répondre de façon fiable à partir de ce document seul. Les informations nécessaires ne sont pas clairement présentes ou exploitables.',
            DocumentSummaryAudience::ADMINISTRATIVE => 'Le document ne contient pas suffisamment d’éléments explicites pour fournir une réponse administrative fiable.',
            default => 'Réponse impossible de manière fiable: le document ne contient pas d’éléments explicites suffisants.',
        };

        return new DocumentQuestionAnswerResult(
            question: $question,
            audience: $audience,
            answer: $answer,
            insufficientEvidence: true,
            evidence: [],
            uncertaintyNotes: $notes,
            usedStructuredFields: [],
            confidenceScore: 0.20,
        );
    }

    private function matchStructuredFields(string $question, array $structuredFields): array
    {
        $normalizedQuestion = mb_strtolower($question);
        $matched = [];

        foreach (self::FIELD_KEYWORDS as $field => $keywords) {
            foreach ($keywords as $keyword) {
                if (str_contains($normalizedQuestion, $keyword) && array_key_exists($field, $structuredFields)) {
                    $matched[] = $field;
                    break;
                }
            }
        }

        return array_values(array_unique($matched));
    }

    private function findRelevantLines(string $question, string $normalizedText): array
    {
        $tokens = collect(preg_split('/[^[:alnum:]À-ÿ]+/u', mb_strtolower($question)) ?: [])
            ->map(static fn (string $token) => trim($token))
            ->filter(static fn (string $token) => mb_strlen($token) >= 4)
            ->reject(static fn (string $token) => in_array($token, [
                'quel',
                'quelle',
                'quels',
                'quelles',
                'dans',
                'avec',
                'pour',
                'vous',
                'document',
                'cette',
                'cette',
                'peux',
                'peut',
                'savoir',
            ], true))
            ->values()
            ->all();

        if ($tokens === []) {
            return [];
        }

        $lines = preg_split('/\R+/u', $normalizedText) ?: [];
        $scored = [];

        foreach ($lines as $line) {
            $trimmed = trim($line);
            if ($trimmed === '' || mb_strlen($trimmed) < 12) {
                continue;
            }

            $score = 0;
            $lowerLine = mb_strtolower($trimmed);

            foreach ($tokens as $token) {
                if (str_contains($lowerLine, $token)) {
                    $score++;
                }
            }

            if ($score > 0) {
                $scored[] = ['line' => $trimmed, 'score' => $score];
            }
        }

        usort($scored, static fn (array $left, array $right) => $right['score'] <=> $left['score']);

        return array_slice(array_values(array_map(static fn (array $item) => $item['line'], $scored)), 0, 3);
    }

    private function formatFieldAnswer(string $field, string $excerpt, DocumentSummaryAudience $audience): string
    {
        $label = match ($field) {
            'patient_name' => 'Nom du patient',
            'document_date' => 'Date du document',
            'doctor_name' => 'Médecin mentionné',
            'establishment' => 'Établissement',
            'specialty' => 'Spécialité',
            'diagnosis' => 'Diagnostic mentionné',
            'suspected_diagnosis' => 'Hypothèse diagnostique',
            'symptoms' => 'Symptômes mentionnés',
            'medical_history' => 'Antécédents mentionnés',
            'treatments' => 'Traitements mentionnés',
            'requested_exams' => 'Examens demandés',
            'important_lab_results' => 'Résultats importants',
            'recommendations' => 'Recommandations',
            'follow_up_date' => 'Date de suivi',
            default => $field,
        };

        return match ($audience) {
            DocumentSummaryAudience::PATIENT => $label.': '.$excerpt.'.',
            DocumentSummaryAudience::ADMINISTRATIVE => $label.' => '.$excerpt.'.',
            default => $label.': '.$excerpt.'.',
        };
    }

    private function composeAudienceAnswer(DocumentSummaryAudience $audience, array $answers): string
    {
        return match ($audience) {
            DocumentSummaryAudience::PATIENT => 'D’après le document: '.implode(' ', $answers).' Si quelque chose te semble flou, vérifie avec ton médecin.',
            DocumentSummaryAudience::ADMINISTRATIVE => 'Éléments explicitement présents dans le document: '.implode(' ', $answers),
            default => 'Réponse fondée sur les champs extraits du document: '.implode(' ', $answers),
        };
    }

    private function composeTextEvidenceAnswer(DocumentSummaryAudience $audience, array $evidenceLines): string
    {
        $joined = implode(' ', array_map(static fn (string $line) => '"'.$line.'"', $evidenceLines));

        return match ($audience) {
            DocumentSummaryAudience::PATIENT => 'Le document indique notamment: '.$joined.' Je ne peux pas aller au-delà de ce qui est écrit.',
            DocumentSummaryAudience::ADMINISTRATIVE => 'Extraits utiles relevés dans le document: '.$joined,
            default => 'Extraits pertinents du document: '.$joined,
        };
    }

    private function confidenceFromEvidence(int $evidenceCount, bool $structured): float
    {
        $base = $structured ? 0.86 : 0.64;

        return min(0.98, $base + ($evidenceCount * 0.04));
    }
}
