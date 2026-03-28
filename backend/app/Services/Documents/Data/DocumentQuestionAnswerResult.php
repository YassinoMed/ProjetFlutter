<?php

namespace App\Services\Documents\Data;

use App\Enums\DocumentSummaryAudience;

final readonly class DocumentQuestionAnswerResult
{
    public function __construct(
        public string $question,
        public DocumentSummaryAudience $audience,
        public string $answer,
        public bool $insufficientEvidence,
        public array $evidence = [],
        public array $uncertaintyNotes = [],
        public array $usedStructuredFields = [],
        public ?float $confidenceScore = null,
    ) {}

    public function toArray(): array
    {
        return [
            'question' => $this->question,
            'audience' => $this->audience->value,
            'answer' => $this->answer,
            'insufficient_evidence' => $this->insufficientEvidence,
            'evidence' => $this->evidence,
            'uncertainty_notes' => $this->uncertaintyNotes,
            'used_structured_fields' => $this->usedStructuredFields,
            'confidence_score' => $this->confidenceScore,
            'disclaimer' => 'Réponse fondée uniquement sur le document importé. Elle ne remplace pas l’avis médical.',
        ];
    }
}
