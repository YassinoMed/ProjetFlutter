<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class UserE2eeDevice extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'user_id',
        'device_id',
        'device_label',
        'bundle_version',
        'identity_key_algorithm',
        'identity_key_public',
        'signed_pre_key_id',
        'signed_pre_key_public',
        'signed_pre_key_signature',
        'last_seen_at_utc',
        'revoked_at',
    ];

    protected $casts = [
        'last_seen_at_utc' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $device): void {
            if (empty($device->id)) {
                $device->id = (string) Str::uuid();
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function preKeys(): HasMany
    {
        return $this->hasMany(UserE2eePreKey::class);
    }
}
