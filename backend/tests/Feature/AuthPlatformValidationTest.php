<?php

namespace Tests\Feature;

use App\Models\User;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class AuthPlatformValidationTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
    }

    public function test_login_accepts_web_platform_and_registers_trusted_device(): void
    {
        $user = User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'device_id' => 'device-web-1',
            'device_name' => 'Web Browser',
            'platform' => 'web',
        ]);

        $response->assertOk();
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('data.user.email', 'patient@example.com');

        $this->assertDatabaseHas('trusted_devices', [
            'user_id' => $user->id,
            'device_id' => 'device-web-1',
            'platform' => 'web',
        ]);
    }

    public function test_login_rejects_unknown_platform_values(): void
    {
        User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'platform' => 'blackberry-os',
        ]);

        $response->assertStatus(422);
        $response->assertJsonPath('success', false);
        $response->assertJsonPath('error.errors.platform.0', 'The selected platform is invalid.');
    }
}
