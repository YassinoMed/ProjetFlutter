<?php

namespace App\Models;

use App\Enums\CallSessionState;
use App\Enums\CallType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class CallSession extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'consultation_id',
        'conversation_id',
        'initiated_by_user_id',
        'ended_by_user_id',
        'call_type',
        'current_state',
        'started_ringing_at_utc',
        'accepted_at_utc',
        'ended_at_utc',
        'expires_at_utc',
        'end_reason',
        'server_metadata',
    ];

    protected $casts = [
        'call_type' => CallType::class,
        'current_state' => CallSessionState::class,
        'started_ringing_at_utc' => 'datetime',
        'accepted_at_utc' => 'datetime',
        'ended_at_utc' => 'datetime',
        'expires_at_utc' => 'datetime',
        'server_metadata' => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $session): void {
            if (empty($session->id)) {
                $session->id = (string) Str::uuid();
            }
        });
    }

    public function consultation(): BelongsTo
    {
        return $this->belongsTo(Appointment::class, 'consultation_id');
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function initiator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'initiated_by_user_id');
    }

    public function endedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'ended_by_user_id');
    }

    public function participants(): HasMany
    {
        return $this->hasMany(CallParticipant::class);
    }
}
