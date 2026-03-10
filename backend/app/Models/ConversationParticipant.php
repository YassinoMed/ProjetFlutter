<?php

namespace App\Models;

use App\Enums\ConversationParticipantRole;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConversationParticipant extends Model
{
    protected $fillable = [
        'conversation_id',
        'user_id',
        'role',
        'is_active',
        'joined_at_utc',
        'last_seen_at_utc',
        'last_delivered_at_utc',
        'last_read_at_utc',
    ];

    protected $casts = [
        'role' => ConversationParticipantRole::class,
        'is_active' => 'boolean',
        'joined_at_utc' => 'datetime',
        'last_seen_at_utc' => 'datetime',
        'last_delivered_at_utc' => 'datetime',
        'last_read_at_utc' => 'datetime',
    ];

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
