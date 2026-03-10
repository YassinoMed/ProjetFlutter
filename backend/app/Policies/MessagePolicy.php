<?php

namespace App\Policies;

use App\Models\Message;
use App\Models\User;

class MessagePolicy
{
    public function view(User $user, Message $message): bool
    {
        return $message->conversation()
            ->whereHas('participants', function ($query) use ($user) {
                $query->where('user_id', $user->id)->where('is_active', true);
            })
            ->exists();
    }
}
