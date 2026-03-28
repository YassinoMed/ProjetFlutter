<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DocumentAccessLog extends Model
{
    protected $fillable = [
        'document_id',
        'actor_user_id',
        'action',
        'audience',
        'ip_address',
        'user_agent',
        'context',
        'accessed_at_utc',
    ];

    protected $casts = [
        'context' => 'array',
        'accessed_at_utc' => 'datetime',
    ];

    public function document(): BelongsTo
    {
        return $this->belongsTo(Document::class);
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }
}
