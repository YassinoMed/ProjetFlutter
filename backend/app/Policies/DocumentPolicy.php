<?php

namespace App\Policies;

use App\Enums\SecretaryPermission;
use App\Enums\UserRole;
use App\Models\Document;
use App\Models\User;
use App\Services\DelegationContextService;
use Illuminate\Http\Request;
use Throwable;

class DocumentPolicy
{
    public function viewAny(User $user): bool
    {
        if (in_array($user->role, [UserRole::PATIENT, UserRole::DOCTOR, UserRole::ADMIN], true)) {
            return true;
        }

        return $this->secretaryHasDocumentPermission($user);
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

        return $this->secretaryCanAccessDocument($user, $document);
    }

    public function delete(User $user, Document $document): bool
    {
        return $this->view($user, $document);
    }

    public function reanalyze(User $user, Document $document): bool
    {
        return $this->view($user, $document);
    }

    private function secretaryHasDocumentPermission(User $user): bool
    {
        if ($user->role !== UserRole::SECRETARY) {
            return false;
        }

        $request = request();

        if (! $request instanceof Request) {
            return false;
        }

        try {
            app(DelegationContextService::class)
                ->assertSecretaryPermission($request, SecretaryPermission::MANAGE_DOCUMENTS);

            return true;
        } catch (Throwable) {
            return false;
        }
    }

    private function secretaryCanAccessDocument(User $user, Document $document): bool
    {
        if (! $this->secretaryHasDocumentPermission($user)) {
            return false;
        }

        $request = request();
        $actingDoctorUserId = app(DelegationContextService::class)->effectiveDoctorUserId($request);

        return $actingDoctorUserId !== null
            && $document->doctor_user_id === $actingDoctorUserId;
    }
}
