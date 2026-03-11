<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Document;
use App\Models\User;

class DocumentPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, [UserRole::PATIENT, UserRole::DOCTOR, UserRole::ADMIN], true);
    }

    public function create(User $user): bool
    {
        return $this->viewAny($user);
    }

    public function view(User $user, Document $document): bool
    {
        if ($user->role === UserRole::ADMIN) {
            return true;
        }

        if ($document->uploaded_by_user_id === $user->id) {
            return true;
        }

        if ($user->role === UserRole::PATIENT) {
            return $document->patient_user_id === $user->id;
        }

        if ($user->role === UserRole::DOCTOR) {
            return $document->doctor_user_id === $user->id;
        }

        return false;
    }

    public function delete(User $user, Document $document): bool
    {
        return $this->view($user, $document);
    }

    public function reanalyze(User $user, Document $document): bool
    {
        return $this->view($user, $document);
    }
}
