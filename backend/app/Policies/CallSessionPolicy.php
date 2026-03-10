<?php

namespace App\Policies;

use App\Models\CallSession;
use App\Models\User;

class CallSessionPolicy
{
    public function view(User $user, CallSession $callSession): bool
    {
        return $callSession->participants()
            ->where('user_id', $user->id)
            ->exists();
    }
}
