<?php

namespace App\Services\Documents\Contracts;

use App\Models\Document;
use App\Services\Documents\Data\DocumentAnalysisResult;
use App\Services\Documents\Data\TextExtractionResult;

interface DocumentAiAnalyzer
{
    public function analyze(Document $document, TextExtractionResult $extraction): DocumentAnalysisResult;
}
