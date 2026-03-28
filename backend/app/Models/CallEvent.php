<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CallEvent extends Model
{
    protected $fillable = [
        'teleconsultation_id',
        'call_session_id',
        'actor_user_id',
        'target_user_id',
        'event_name',
        'direction',
        'payload',
        'occurred_at_utc',
    ];

    protected $casts = [
        'payload' => 'array',
        'occurred_at_utc' => 'datetime',
    ];

    public function teleconsultation(): BelongsTo
    {
        return $this->belongsTo(Teleconsultation::class);
    }

    public function callSession(): BelongsTo
    {
        return $this->belongsTo(CallSession::class);
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }

    public function target(): BelongsTo
    {
        return $this->belongsTo(User::class, 'target_user_id');
    }
}
