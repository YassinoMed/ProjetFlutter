<?php

namespace App\Models;

use App\Enums\ConversationType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Conversation extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'consultation_id',
        'initiated_by_user_id',
        'type',
        'last_message_at_utc',
        'server_metadata',
    ];

    protected $casts = [
        'type' => ConversationType::class,
        'last_message_at_utc' => 'datetime',
        'server_metadata' => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $conversation): void {
            if (empty($conversation->id)) {
                $conversation->id = (string) Str::uuid();
            }
        });
    }

    public function consultation(): BelongsTo
    {
        return $this->belongsTo(Appointment::class, 'consultation_id');
    }

    public function initiator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'initiated_by_user_id');
    }

    public function participants(): HasMany
    {
        return $this->hasMany(ConversationParticipant::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function callSessions(): HasMany
    {
        return $this->hasMany(CallSession::class);
    }
}
