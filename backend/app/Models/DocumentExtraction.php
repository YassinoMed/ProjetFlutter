<?php

namespace App\Models;

use App\Enums\DocumentProcessingStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentExtraction extends Model
{
    protected $fillable = [
        'document_id',
        'version',
        'status',
        'source',
        'engine',
        'language_code',
        'raw_text_encrypted',
        'normalized_text_encrypted',
        'structured_payload',
        'missing_sections',
        'confidence_score',
        'started_at_utc',
        'completed_at_utc',
        'failed_at_utc',
        'error_code',
        'error_message_sanitized',
        'meta',
    ];

    protected $casts = [
        'status' => DocumentProcessingStatus::class,
        'raw_text_encrypted' => 'encrypted',
        'normalized_text_encrypted' => 'encrypted',
        'structured_payload' => 'array',
        'missing_sections' => 'array',
        'confidence_score' => 'decimal:2',
        'started_at_utc' => 'datetime',
        'completed_at_utc' => 'datetime',
        'failed_at_utc' => 'datetime',
        'meta' => 'array',
    ];

    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }
}
