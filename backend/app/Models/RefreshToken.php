<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RefreshToken extends Model
{
    protected $table = 'refresh_tokens';

    protected $fillable = [
        'user_id',
        'jti_hash',
        'replaced_by_jti_hash',
        'revoked_at_utc',
        'expires_at_utc',
        'issued_ip',
        'issued_user_agent',
    ];

    protected $casts = [
        'revoked_at_utc' => 'datetime',
        'expires_at_utc' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeActive($query)
    {
        return $query
            ->whereNull('revoked_at_utc')
            ->where('expires_at_utc', '>', now('UTC'));
    }
}
