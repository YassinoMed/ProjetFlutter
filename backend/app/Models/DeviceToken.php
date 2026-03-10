<?php

namespace App\Models;

use App\Enums\DeviceTokenProvider;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeviceToken extends Model
{
    protected $fillable = [
        'user_id',
        'provider',
        'token',
        'platform',
        'device_label',
        'last_seen_at_utc',
        'revoked_at',
    ];

    protected $casts = [
        'provider' => DeviceTokenProvider::class,
        'last_seen_at_utc' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
