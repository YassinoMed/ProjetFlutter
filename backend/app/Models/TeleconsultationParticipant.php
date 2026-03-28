<?php

namespace App\Models;

use App\Enums\TeleconsultationParticipantRole;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeleconsultationParticipant extends Model
{
    protected $fillable = [
        'teleconsultation_id',
        'user_id',
        'role',
        'invited_at_utc',
        'joined_at_utc',
        'left_at_utc',
        'last_seen_at_utc',
        'can_publish_audio',
        'can_publish_video',
        'access_revoked_at_utc',
    ];

    protected $casts = [
        'role' => TeleconsultationParticipantRole::class,
        'invited_at_utc' => 'datetime',
        'joined_at_utc' => 'datetime',
        'left_at_utc' => 'datetime',
        'last_seen_at_utc' => 'datetime',
        'can_publish_audio' => 'boolean',
        'can_publish_video' => 'boolean',
        'access_revoked_at_utc' => 'datetime',
    ];

    public function teleconsultation(): BelongsTo
    {
        return $this->belongsTo(Teleconsultation::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
