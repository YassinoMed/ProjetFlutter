<?php

namespace App\Models;

use App\Enums\DocumentProcessingStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentProcessingJob extends Model
{
    protected $fillable = [
        'document_id',
        'job_type',
        'queue_name',
        'attempt',
        'status',
        'started_at_utc',
        'completed_at_utc',
        'failed_at_utc',
        'error_code',
        'error_message_sanitized',
        'meta',
    ];

    protected $casts = [
        'status' => DocumentProcessingStatus::class,
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
