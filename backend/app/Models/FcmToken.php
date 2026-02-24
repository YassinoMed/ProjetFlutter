<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FcmToken extends Model
{
    protected $table = 'fcm_tokens';

    protected $fillable = [
        'user_id',
        'token',
        'platform',
        'last_seen_at_utc',
    ];

    protected $casts = [
        'last_seen_at_utc' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
