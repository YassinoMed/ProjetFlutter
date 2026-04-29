<?php

namespace Tests;

use App\Http\Middleware\TenantMiddleware;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Schema;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->prepareTestingEnvironment();
    }

    private function prepareTestingEnvironment(): void
    {
        $this->withoutMiddleware(TenantMiddleware::class);

        if (blank(config('app.key'))) {
            Config::set('app.key', 'base64:'.base64_encode(str_repeat('t', 32)));
        }

        if (! $this->shouldBootstrapTenantSchema()) {
            return;
        }

        Artisan::call('migrate', [
            '--path' => database_path('migrations/tenant'),
            '--realpath' => true,
            '--force' => true,
        ]);
    }

    private function shouldBootstrapTenantSchema(): bool
    {
        if (! app()->environment('testing')) {
            return false;
        }

        if (config('database.default') !== 'sqlite') {
            return false;
        }

        if (! Schema::hasTable('migrations')) {
            return false;
        }

        return ! Schema::hasTable('users');
    }
}
