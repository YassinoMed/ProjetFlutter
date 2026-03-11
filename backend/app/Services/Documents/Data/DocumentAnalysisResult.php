<?php

namespace App\Services\Documents\Data;

use App\Enums\DocumentType;
use App\Enums\DocumentUrgency;

final readonly class DocumentAnalysisResult
{
    public function __construct(
        public ?DocumentType $documentType,
        public DocumentUrgency $urgency,
        public float $classificationConfidence,
        public array $structuredFields,
        public array $entities,
        public array $summaries,
        public array $tags,
        public array $warnings = [],
        public array $missingInformation = [],
        public ?string $languageCode = null,
    ) {}
}
