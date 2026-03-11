<?php

namespace App\Models;

use App\Enums\DelegationStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class DoctorSecretaryDelegation extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'doctor_user_id',
        'secretary_user_id',
        'invited_by_user_id',
        'revoked_by_user_id',
        'invited_email',
        'invited_first_name',
        'invited_last_name',
        'status',
        'activated_at_utc',
        'suspended_at_utc',
        'revoked_at_utc',
        'last_used_at_utc',
        'suspension_reason',
        'revocation_reason',
        'context_snapshot',
    ];

    protected $casts = [
        'status' => DelegationStatus::class,
        'activated_at_utc' => 'datetime',
        'suspended_at_utc' => 'datetime',
        'revoked_at_utc' => 'datetime',
        'last_used_at_utc' => 'datetime',
        'context_snapshot' => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $delegation): void {
            if (empty($delegation->id)) {
                $delegation->id = (string) Str::uuid();
            }
        });
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_user_id');
    }

    public function secretary(): BelongsTo
    {
        return $this->belongsTo(User::class, 'secretary_user_id');
    }

    public function invitedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'invited_by_user_id');
    }

    public function revokedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'revoked_by_user_id');
    }

    public function permissions(): HasMany
    {
        return $this->hasMany(DoctorSecretaryPermission::class, 'delegation_id');
    }

    public function invitations(): HasMany
    {
        return $this->hasMany(SecretaryInvitation::class, 'delegation_id');
    }
}
