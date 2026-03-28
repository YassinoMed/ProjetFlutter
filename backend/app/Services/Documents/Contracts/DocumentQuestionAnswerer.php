<?php

namespace App\Services\Documents\Contracts;

use App\Enums\DocumentSummaryAudience;
use App\Models\Document;
use App\Services\Documents\Data\DocumentQuestionAnswerResult;

interface DocumentQuestionAnswerer
{
    public function answer(Document $document, string $question, DocumentSummaryAudience $audience): DocumentQuestionAnswerResult;
}
