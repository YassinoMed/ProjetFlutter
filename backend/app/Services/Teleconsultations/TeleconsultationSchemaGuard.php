<?php

namespace App\Services\Teleconsultations;

use Illuminate\Support\Facades\Schema;
use Symfony\Component\HttpKernel\Exception\ServiceUnavailableHttpException;

class TeleconsultationSchemaGuard
{
    private const REQUIRED_TABLES = [
        'teleconsultations',
        'teleconsultation_participants',
        'call_events',
    ];

    public function isAvailable(): bool
    {
        foreach (self::REQUIRED_TABLES as $table) {
            if (! Schema::hasTable($table)) {
                return false;
            }
        }

        return true;
    }

    public function ensureAvailable(): void
    {
        if ($this->isAvailable()) {
            return;
        }

        throw new ServiceUnavailableHttpException(
            null,
            'Teleconsultation is temporarily unavailable for this tenant.',
        );
    }
}
