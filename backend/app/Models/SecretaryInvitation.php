<?php

namespace App\Models;

use App\Enums\SecretaryInvitationStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class SecretaryInvitation extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'delegation_id',
        'created_by_user_id',
        'email',
        'token_hash',
        'status',
        'expires_at_utc',
        'accepted_at_utc',
        'revoked_at_utc',
    ];

    protected $casts = [
        'status' => SecretaryInvitationStatus::class,
        'expires_at_utc' => 'datetime',
        'accepted_at_utc' => 'datetime',
        'revoked_at_utc' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $invitation): void {
            if (empty($invitation->id)) {
                $invitation->id = (string) Str::uuid();
            }
        });
    }

    public function delegation(): BelongsTo
    {
        return $this->belongsTo(DoctorSecretaryDelegation::class, 'delegation_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
