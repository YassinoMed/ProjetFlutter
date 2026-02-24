<?php

namespace App\Models;

use App\Enums\ChatMessageStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessageStatusEntry extends Model
{
    public $timestamps = false;

    protected $table = 'chat_message_statuses';

    protected $fillable = [
        'message_id',
        'user_id',
        'status',
        'status_at_utc',
    ];

    protected $casts = [
        'status' => ChatMessageStatus::class,
        'status_at_utc' => 'datetime',
    ];

    public function message(): BelongsTo
    {
        return $this->belongsTo(ChatMessage::class, 'message_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
