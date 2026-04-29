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

    public function accept(User $user, CallSession $callSession): bool
    {
        return $this->view($user, $callSession)
            && $callSession->initiated_by_user_id !== $user->id;
    }

    public function reject(User $user, CallSession $callSession): bool
    {
        return $this->accept($user, $callSession);
    }

    public function cancel(User $user, CallSession $callSession): bool
    {
        return $this->view($user, $callSession)
            && $callSession->initiated_by_user_id === $user->id;
    }

    public function end(User $user, CallSession $callSession): bool
    {
        return $this->view($user, $callSession);
    }

    public function signal(User $user, CallSession $callSession): bool
    {
        return $this->view($user, $callSession);
    }
}
