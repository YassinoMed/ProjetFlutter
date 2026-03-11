<?php

namespace App\Services\Documents\Data;

final readonly class TextExtractionResult
{
    public function __construct(
        public string $rawText,
        public string $normalizedText,
        public string $source,
        public string $engine,
        public ?string $languageCode = null,
        public bool $ocrUsed = false,
        public bool $ocrRequired = false,
        public ?float $confidenceScore = null,
        public array $meta = [],
    ) {}
}
