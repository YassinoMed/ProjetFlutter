<?php

namespace App\Services\DoctorSecretaries;

use App\Enums\DelegationStatus;
use App\Enums\SecretaryInvitationStatus;
use App\Enums\UserRole;
use App\Models\DoctorSecretaryDelegation;
use App\Models\DoctorSecretaryPermission;
use App\Models\SecretaryInvitation;
use App\Models\User;
use App\Services\AuditService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class DoctorSecretaryService
{
    public function __construct(private readonly AuditService $auditService) {}

    public function listForDoctor(User $doctor): Collection
    {
        return DoctorSecretaryDelegation::query()
            ->with(['secretary', 'permissions', 'invitations'])
            ->where('doctor_user_id', $doctor->id)
            ->orderByDesc('created_at')
            ->get();
    }

    public function invite(User $doctor, array $payload): array
    {
        $this->assertDoctor($doctor);

        $existingDelegation = DoctorSecretaryDelegation::query()
            ->where('doctor_user_id', $doctor->id)
            ->where('invited_email', $payload['email'])
            ->first();

        if ($existingDelegation !== null) {
            throw ValidationException::withMessages([
                'email' => ['This secretary email is already linked to your account.'],
            ]);
        }

        $existingUser = User::query()->where('email', $payload['email'])->first();

        if ($existingUser !== null && $existingUser->role !== UserRole::SECRETARY) {
            throw ValidationException::withMessages([
                'email' => ['This email is already used by a non-secretary account.'],
            ]);
        }

        $plainToken = Str::random(64);

        return DB::transaction(function () use ($doctor, $payload, $existingUser, $plainToken): array {
            $delegation = DoctorSecretaryDelegation::query()->create([
                'doctor_user_id' => $doctor->id,
                'secretary_user_id' => $existingUser?->id,
                'invited_by_user_id' => $doctor->id,
                'invited_email' => $payload['email'],
                'invited_first_name' => $payload['first_name'],
                'invited_last_name' => $payload['last_name'],
                'status' => DelegationStatus::PENDING->value,
                'context_snapshot' => [
                    'doctor_name' => trim($doctor->first_name.' '.$doctor->last_name),
                ],
            ]);

            foreach (array_unique($payload['permissions']) as $permission) {
                DoctorSecretaryPermission::query()->create([
                    'delegation_id' => $delegation->id,
                    'permission' => $permission,
                ]);
            }

            $invitation = SecretaryInvitation::query()->create([
                'delegation_id' => $delegation->id,
                'created_by_user_id' => $doctor->id,
                'email' => $payload['email'],
                'token_hash' => Hash::make($plainToken),
                'status' => SecretaryInvitationStatus::PENDING->value,
                'expires_at_utc' => now('UTC')->addHours($payload['expires_in_hours'] ?? 72),
            ]);

            $delegation = $delegation->load(['secretary', 'permissions', 'invitations']);

            $this->auditService->log($doctor, 'secretary.invited', $delegation, [
                'invitation_id' => $invitation->id,
                'permissions' => $payload['permissions'],
                'invite_email' => $payload['email'],
            ]);

            return [
                'delegation' => $delegation,
                'invitation' => $invitation,
                'plain_token' => $plainToken,
            ];
        });
    }

    public function acceptInvitation(array $payload): DoctorSecretaryDelegation
    {
        /** @var SecretaryInvitation|null $invitation */
        $invitation = SecretaryInvitation::query()
            ->with(['delegation.permissions', 'delegation.doctor'])
            ->where('status', SecretaryInvitationStatus::PENDING->value)
            ->get()
            ->first(function (SecretaryInvitation $candidate) use ($payload): bool {
                return Hash::check($payload['token'], $candidate->token_hash);
            });

        if ($invitation === null) {
            throw ValidationException::withMessages([
                'token' => ['Invitation token is invalid.'],
            ]);
        }

        if ($invitation->expires_at_utc->isPast()) {
            $invitation->forceFill([
                'status' => SecretaryInvitationStatus::EXPIRED->value,
            ])->save();

            throw ValidationException::withMessages([
                'token' => ['Invitation token has expired.'],
            ]);
        }

        return DB::transaction(function () use ($invitation, $payload): DoctorSecretaryDelegation {
            $secretary = User::query()->firstWhere('email', $invitation->email);

            if ($secretary !== null && $secretary->role !== UserRole::SECRETARY) {
                throw ValidationException::withMessages([
                    'email' => ['This email is already linked to another role.'],
                ]);
            }

            if ($secretary === null) {
                $secretary = User::query()->create([
                    'email' => $invitation->email,
                    'password' => $payload['password'],
                    'first_name' => $payload['first_name'],
                    'last_name' => $payload['last_name'],
                    'phone' => $payload['phone'] ?? null,
                    'role' => UserRole::SECRETARY,
                ]);
            } else {
                $secretary->forceFill([
                    'password' => $payload['password'],
                    'first_name' => $payload['first_name'],
                    'last_name' => $payload['last_name'],
                    'phone' => $payload['phone'] ?? $secretary->phone,
                    'role' => UserRole::SECRETARY,
                ])->save();
            }

            $delegation = $invitation->delegation;

            $delegation->forceFill([
                'secretary_user_id' => $secretary->id,
                'status' => DelegationStatus::ACTIVE->value,
                'activated_at_utc' => now('UTC'),
            ])->save();

            $invitation->forceFill([
                'status' => SecretaryInvitationStatus::ACCEPTED->value,
                'accepted_at_utc' => now('UTC'),
            ])->save();

            $delegation = $delegation->fresh(['secretary', 'doctor', 'permissions', 'invitations']);

            $this->auditService->log($secretary, 'secretary.invitation.accepted', $delegation, [
                'doctor_user_id' => $delegation->doctor_user_id,
            ], actingDoctorUserId: $delegation->doctor_user_id, delegationId: $delegation->id);

            return $delegation;
        });
    }

    public function updatePermissions(User $doctor, DoctorSecretaryDelegation $delegation, array $permissions): DoctorSecretaryDelegation
    {
        $this->assertDoctorOwnsDelegation($doctor, $delegation);

        return DB::transaction(function () use ($doctor, $delegation, $permissions): DoctorSecretaryDelegation {
            $delegation->permissions()->delete();

            foreach (array_unique($permissions) as $permission) {
                DoctorSecretaryPermission::query()->create([
                    'delegation_id' => $delegation->id,
                    'permission' => $permission,
                ]);
            }

            $delegation = $delegation->fresh(['secretary', 'permissions', 'invitations']);

            $this->auditService->log($doctor, 'secretary.permissions.updated', $delegation, [
                'permissions' => $permissions,
            ]);

            return $delegation;
        });
    }

    public function suspend(User $doctor, DoctorSecretaryDelegation $delegation, ?string $reason = null): DoctorSecretaryDelegation
    {
        $this->assertDoctorOwnsDelegation($doctor, $delegation);

        $delegation->forceFill([
            'status' => DelegationStatus::SUSPENDED->value,
            'suspended_at_utc' => now('UTC'),
            'suspension_reason' => $reason,
        ])->save();

        $this->auditService->log($doctor, 'secretary.suspended', $delegation, [
            'reason' => $reason,
        ]);

        return $delegation->fresh(['secretary', 'permissions', 'invitations']);
    }

    public function reactivate(User $doctor, DoctorSecretaryDelegation $delegation): DoctorSecretaryDelegation
    {
        $this->assertDoctorOwnsDelegation($doctor, $delegation);

        $delegation->forceFill([
            'status' => DelegationStatus::ACTIVE->value,
            'suspended_at_utc' => null,
            'suspension_reason' => null,
        ])->save();

        $this->auditService->log($doctor, 'secretary.reactivated', $delegation);

        return $delegation->fresh(['secretary', 'permissions', 'invitations']);
    }

    public function revoke(User $doctor, DoctorSecretaryDelegation $delegation): void
    {
        $this->assertDoctorOwnsDelegation($doctor, $delegation);

        DB::transaction(function () use ($doctor, $delegation): void {
            $delegation->forceFill([
                'status' => DelegationStatus::REVOKED->value,
                'revoked_at_utc' => now('UTC'),
                'revoked_by_user_id' => $doctor->id,
            ])->save();

            $delegation->invitations()
                ->where('status', SecretaryInvitationStatus::PENDING->value)
                ->update([
                    'status' => SecretaryInvitationStatus::REVOKED->value,
                    'revoked_at_utc' => now('UTC'),
                ]);

            $this->auditService->log($doctor, 'secretary.revoked', $delegation);
        });
    }

    public function delegationsForSecretary(User $secretary): Collection
    {
        return DoctorSecretaryDelegation::query()
            ->with(['doctor', 'permissions'])
            ->where('secretary_user_id', $secretary->id)
            ->whereIn('status', [DelegationStatus::ACTIVE->value, DelegationStatus::SUSPENDED->value])
            ->orderByDesc('last_used_at_utc')
            ->orderByDesc('created_at')
            ->get();
    }

    public function assertActiveDelegation(User $secretary, string $doctorUserId): DoctorSecretaryDelegation
    {
        $delegation = DoctorSecretaryDelegation::query()
            ->with(['doctor', 'permissions'])
            ->where('secretary_user_id', $secretary->id)
            ->where('doctor_user_id', $doctorUserId)
            ->where('status', DelegationStatus::ACTIVE->value)
            ->first();

        if ($delegation === null) {
            throw new AuthorizationException('Active delegation not found for this doctor.');
        }

        return $delegation;
    }

    public function touchDelegationUsage(DoctorSecretaryDelegation $delegation): void
    {
        $delegation->forceFill([
            'last_used_at_utc' => now('UTC'),
        ])->save();
    }

    private function assertDoctor(User $doctor): void
    {
        if (! in_array($doctor->role, [UserRole::DOCTOR, UserRole::ADMIN], true)) {
            throw new AuthorizationException('Only doctors can manage secretaries.');
        }
    }

    private function assertDoctorOwnsDelegation(User $doctor, DoctorSecretaryDelegation $delegation): void
    {
        $this->assertDoctor($doctor);

        if ($delegation->doctor_user_id !== $doctor->id && $doctor->role !== UserRole::ADMIN) {
            throw new AuthorizationException('You do not own this secretary delegation.');
        }
    }
}
