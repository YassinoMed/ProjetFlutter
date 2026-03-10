<?php

namespace App\Models;

use App\Enums\CallParticipantRole;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CallParticipant extends Model
{
    protected $fillable = [
        'call_session_id',
        'user_id',
        'role',
        'joined_at_utc',
        'left_at_utc',
        'last_seen_at_utc',
    ];

    protected $casts = [
        'role' => CallParticipantRole::class,
        'joined_at_utc' => 'datetime',
        'left_at_utc' => 'datetime',
        'last_seen_at_utc' => 'datetime',
    ];

    public function callSession(): BelongsTo
    {
        return $this->belongsTo(CallSession::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
