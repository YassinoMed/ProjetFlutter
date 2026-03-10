<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class AuditService
{
    public function log(?User $actor, string $event, Model|string|null $auditable = null, array $context = []): void
    {
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
            'event' => $event,
            'auditable_type' => $auditableType,
            'auditable_id' => $auditableId,
            'context' => $context,
        ]);
    }
}
