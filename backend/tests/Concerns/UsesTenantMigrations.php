<?php

namespace Tests\Concerns;

use App\Http\Middleware\TenantMiddleware;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schema;

trait UsesTenantMigrations
{
    protected function bootTenantSchema(): void
    {
        $this->withoutMiddleware(TenantMiddleware::class);

        Artisan::call('migrate:fresh', [
            '--path' => database_path('migrations/tenant'),
            '--realpath' => true,
        ]);

        Schema::dropIfExists('personal_access_tokens');

        Artisan::call('migrate', [
            '--path' => base_path('vendor/laravel/sanctum/database/migrations'),
            '--realpath' => true,
        ]);
    }
}
