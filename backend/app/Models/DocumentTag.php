<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentTag extends Model
{
    protected $fillable = [
        'document_id',
        'tag',
        'confidence_score',
    ];

    protected $casts = [
        'confidence_score' => 'decimal:2',
    ];

    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }
}
