<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class AuditService
{
    public function log(
        ?User $actor,
        string $event,
        Model|string|null $auditable = null,
        array $context = [],
        ?string $actingDoctorUserId = null,
        ?string $delegationId = null,
        ?Request $request = null,
    ): void {
        $auditableType = null;
        $auditableId = null;

        if ($auditable instanceof Model) {
            $auditableType = $auditable::class;
            $auditableId = (string) $auditable->getKey();
        } elseif (is_string($auditable)) {
            $auditableType = $auditable;
        }

        AuditLog::query()->create([
            'actor_user_id' => $actor?->id,
            'actor_role' => $actor?->role?->value ?? $actor?->role,
            'acting_doctor_user_id' => $actingDoctorUserId,
            'delegation_id' => $delegationId,
            'event' => $event,
            'auditable_type' => $auditableType,
            'auditable_id' => $auditableId,
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
            'context' => $context,
        ]);
    }
}
