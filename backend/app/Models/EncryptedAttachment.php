<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Support\Str;

class EncryptedAttachment extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'owner_user_id',
        'attachable_type',
        'attachable_id',
        'original_filename',
        'mime_type',
        'file_size_bytes',
        'storage_path',
        'encrypted_key',
        'key_id',
        'nonce',
        'algorithm',
        'checksum_sha256',
        'expires_at',
    ];

    protected $casts = [
        'file_size_bytes' => 'integer',
        'expires_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $attachment): void {
            if (empty($attachment->id)) {
                $attachment->id = (string) Str::uuid();
            }
        });
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function attachable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * Check if this attachment has expired (RGPD data minimization).
     */
    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    /**
     * Scope: non-expired attachments only.
     */
    public function scopeActive($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('expires_at')
              ->orWhere('expires_at', '>', now());
        });
    }
}
