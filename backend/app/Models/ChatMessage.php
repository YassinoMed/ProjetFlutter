<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Support\Str;

class ChatMessage extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'consultation_id',
        'sender_user_id',
        'recipient_user_id',
        'ciphertext',
        'nonce',
        'algorithm',
        'key_id',
        'metadata_encrypted',
        'sent_at_utc',
        'expires_at',
    ];

    protected $casts = [
        'metadata_encrypted' => 'array',
        'sent_at_utc' => 'datetime',
        'expires_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $message): void {
            if (empty($message->id)) {
                $message->id = (string) Str::uuid();
            }
            // RGPD Data Minimization: auto-set TTL
            if ($message->expires_at === null) {
                $ttlDays = (int) env('CHAT_MESSAGE_TTL_DAYS', 730);
                if ($ttlDays > 0) {
                    $message->expires_at = now()->addDays($ttlDays);
                }
            }
        });
    }

    public function consultation(): BelongsTo
    {
        return $this->belongsTo(Appointment::class, 'consultation_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }

    public function recipient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recipient_user_id');
    }

    public function statuses(): HasMany
    {
        return $this->hasMany(ChatMessageStatusEntry::class, 'message_id');
    }

    /**
     * E2EE encrypted file attachments.
     */
    public function attachments(): MorphMany
    {
        return $this->morphMany(EncryptedAttachment::class, 'attachable');
    }

    /**
     * Scope: only non-expired messages.
     */
    public function scopeActive($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('expires_at')
                ->orWhere('expires_at', '>', now());
        });
    }
}
