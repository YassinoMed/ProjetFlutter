<?php

namespace App\Services\Documents\Contracts;

use App\Models\Document;
use App\Services\Documents\Data\TextExtractionResult;

interface DocumentTextExtractor
{
    public function extract(Document $document): TextExtractionResult;
}
