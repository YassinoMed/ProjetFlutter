<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentEntity extends Model
{
    protected $fillable = [
        'document_id',
        'version',
        'entity_type',
        'label',
        'value_encrypted',
        'is_sensitive',
        'confidence_score',
        'qualifiers',
    ];

    protected $casts = [
        'value_encrypted' => 'encrypted',
        'is_sensitive' => 'boolean',
        'confidence_score' => 'decimal:2',
        'qualifiers' => 'array',
    ];

    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }
}
