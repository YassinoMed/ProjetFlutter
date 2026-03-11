<?php

namespace App\Models;

use App\Enums\DocumentProcessingStatus;
use App\Enums\DocumentType;
use App\Enums\DocumentUrgency;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class Document extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'patient_user_id',
        'doctor_user_id',
        'uploaded_by_user_id',
        'title',
        'original_filename',
        'mime_type',
        'file_extension',
        'file_size_bytes',
        'storage_disk',
        'storage_path',
        'sha256_checksum',
        'document_type',
        'processing_status',
        'extraction_status',
        'summary_status',
        'ocr_required',
        'ocr_used',
        'urgency_level',
        'language_code',
        'document_date_utc',
        'processed_at_utc',
        'failed_at_utc',
        'classification_confidence',
        'last_error_code',
        'last_error_message_sanitized',
        'source_metadata',
    ];

    protected $casts = [
        'document_type' => DocumentType::class,
        'processing_status' => DocumentProcessingStatus::class,
        'extraction_status' => DocumentProcessingStatus::class,
        'summary_status' => DocumentProcessingStatus::class,
        'ocr_required' => 'boolean',
        'ocr_used' => 'boolean',
        'urgency_level' => DocumentUrgency::class,
        'document_date_utc' => 'datetime',
        'processed_at_utc' => 'datetime',
        'failed_at_utc' => 'datetime',
        'classification_confidence' => 'decimal:2',
        'source_metadata' => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $document): void {
            if (empty($document->id)) {
                $document->id = (string) Str::uuid();
            }
        });
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'patient_user_id');
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_user_id');
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by_user_id');
    }

    public function extractions(): HasMany
    {
        return $this->hasMany(DocumentExtraction::class);
    }

    public function latestExtraction(): HasOne
    {
        return $this->hasOne(DocumentExtraction::class)->latestOfMany('version');
    }

    public function summaries(): HasMany
    {
        return $this->hasMany(DocumentSummary::class);
    }

    public function entities(): HasMany
    {
        return $this->hasMany(DocumentEntity::class);
    }

    public function tags(): HasMany
    {
        return $this->hasMany(DocumentTag::class);
    }
}
