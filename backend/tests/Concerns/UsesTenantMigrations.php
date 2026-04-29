<?php

namespace Tests\Concerns;

use App\Http\Middleware\TenantMiddleware;
use Illuminate\Support\Facades\Artisan;

trait UsesTenantMigrations
{
    protected function bootTenantSchema(): void
    {
        $this->withoutMiddleware(TenantMiddleware::class);

        Artisan::call('migrate:fresh', [
            '--path' => database_path('migrations/tenant'),
            '--realpath' => true,
        ]);
    }
}
