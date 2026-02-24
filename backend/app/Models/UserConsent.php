<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserConsent extends Model
{
    protected $table = 'user_consents';

    protected $fillable = [
        'user_id',
        'consent_type',
        'consented',
        'consented_at_utc',
        'revoked_at_utc',
    ];

    protected $casts = [
        'consented' => 'bool',
        'consented_at_utc' => 'datetime',
        'revoked_at_utc' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
