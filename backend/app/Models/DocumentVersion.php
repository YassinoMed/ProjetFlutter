<?php

namespace App\Models;

use App\Enums\DocumentType;
use App\Enums\DocumentUrgency;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentVersion extends Model
{
    protected $fillable = [
        'document_id',
        'version',
        'created_by_user_id',
        'document_type',
        'urgency_level',
        'language_code',
        'source',
        'engine',
        'ocr_required',
        'ocr_used',
        'classification_confidence',
        'structured_payload',
        'missing_fields',
        'warnings',
        'processed_at_utc',
    ];

    protected $casts = [
        'document_type' => DocumentType::class,
        'urgency_level' => DocumentUrgency::class,
        'ocr_required' => 'boolean',
        'ocr_used' => 'boolean',
        'classification_confidence' => 'decimal:2',
        'structured_payload' => 'array',
        'missing_fields' => 'array',
        'warnings' => 'array',
        'processed_at_utc' => 'datetime',
    ];

    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
