<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

/**
 * TrustedDevice — tracks each mobile device approved for a user.
 *
 * Biometrics are purely client-side; this table only records
 * whether the user has *chosen* to enable biometric unlock on this device.
 * No fingerprint data is ever stored.
 */
class TrustedDevice extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'user_id',
        'device_id',
        'device_name',
        'platform',
        'biometrics_enabled',
        'last_login_at',
        'revoked_at',
    ];

    protected $casts = [
        'biometrics_enabled' => 'boolean',
        'last_login_at' => 'datetime',
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

    // ── Relationships ────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // ── Scopes ───────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->whereNull('revoked_at');
    }

    public function scopeForDevice($query, string $deviceId)
    {
        return $query->where('device_id', $deviceId);
    }

    // ── Helpers ──────────────────────────────────────────────

    public function isRevoked(): bool
    {
        return $this->revoked_at !== null;
    }

    public function revoke(): void
    {
        $this->update(['revoked_at' => now()]);
    }
}
