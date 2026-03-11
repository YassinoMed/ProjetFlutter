<?php

namespace App\Models;

use App\Enums\DocumentProcessingStatus;
use App\Enums\DocumentSummaryAudience;
use App\Enums\DocumentSummaryFormat;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentSummary extends Model
{
    protected $fillable = [
        'document_id',
        'version',
        'status',
        'audience',
        'format',
        'summary_text_encrypted',
        'structured_payload',
        'factual_basis',
        'missing_fields',
        'confidence_score',
        'generated_at_utc',
    ];

    protected $casts = [
        'status' => DocumentProcessingStatus::class,
        'audience' => DocumentSummaryAudience::class,
        'format' => DocumentSummaryFormat::class,
        'summary_text_encrypted' => 'encrypted',
        'structured_payload' => 'array',
        'factual_basis' => 'array',
        'missing_fields' => 'array',
        'confidence_score' => 'decimal:2',
        'generated_at_utc' => 'datetime',
    ];

    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }
}
