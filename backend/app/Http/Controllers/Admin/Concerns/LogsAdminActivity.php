<?php

namespace App\Http\Controllers\Admin\Concerns;

use Illuminate\Support\Facades\Log;

/**
 * Trait LogsAdminActivity
 *
 * Centralise l'audit logging admin — pattern copié dans 5+ contrôleurs.
 * Ajoute automatiquement admin_id et IP à chaque entrée de log.
 */
trait LogsAdminActivity
{
    /**
     * Log a security-level admin action.
     *
     * @param  string  $event  Event name (e.g. 'doctor_approved', 'admin_export_users')
     * @param  array  $context  Additional context data merged with admin_id/ip
     * @param  string  $level  Log level: 'info', 'warning', 'alert'
     */
    protected function logAdminAction(string $event, array $context = [], string $level = 'info'): void
    {
        $base = [
            'admin_id' => auth('web')->id(),
            'ip' => request()->ip(),
        ];

        Log::channel('security')->log($level, $event, array_merge($base, $context));
    }
}
