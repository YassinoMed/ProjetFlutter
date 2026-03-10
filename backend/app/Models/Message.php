<?php

namespace App\Models;

use App\Enums\MessageType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Message extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'conversation_id',
        'sender_user_id',
        'client_message_id',
        'message_type',
        'ciphertext',
        'nonce',
        'e2ee_version',
        'sender_key_id',
        'server_metadata',
        'sent_at_utc',
        'server_received_at_utc',
        'expires_at',
    ];

    protected $casts = [
        'message_type' => MessageType::class,
        'server_metadata' => 'array',
        'sent_at_utc' => 'datetime',
        'server_received_at_utc' => 'datetime',
        'expires_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $message): void {
            if (empty($message->id)) {
                $message->id = (string) Str::uuid();
            }

            if ($message->server_received_at_utc === null) {
                $message->server_received_at_utc = now('UTC');
            }
        });
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_user_id');
    }

    public function receipts(): HasMany
    {
        return $this->hasMany(MessageReceipt::class);
    }
}
