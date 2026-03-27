<?php

namespace Tests\Feature;

use App\Models\TrustedDevice;
use App\Models\User;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class AuthBiometricDeviceFlowTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
    }

    public function test_login_keeps_a_single_token_per_device_uuid(): void
    {
        $user = User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $payload = [
            'login' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'device_id' => 'device-ios-1',
            'device_name' => 'iPhone 16 Pro',
            'platform' => 'ios',
        ];

        $this->postJson('/api/auth/login', $payload)->assertOk();
        $this->postJson('/api/auth/login', $payload)->assertOk();

        $this->assertDatabaseHas('trusted_devices', [
            'user_id' => $user->id,
            'device_id' => 'device-ios-1',
            'platform' => 'ios',
        ]);

        $this->assertSame(
            1,
            PersonalAccessToken::query()
                ->where('tokenable_id', $user->id)
                ->where('tokenable_type', User::class)
                ->where('name', 'device-ios-1')
                ->count()
        );
    }

    public function test_biometric_can_be_enabled_disabled_and_device_can_be_revoked(): void
    {
        User::query()->create([
            'email' => 'doctor@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc',
            'last_name' => 'Tor',
            'role' => 'DOCTOR',
        ]);

        $loginResponse = $this->postJson('/api/auth/login', [
            'login' => 'doctor@example.com',
            'password' => 'VeryStrongPassword123!',
            'device_id' => 'device-android-1',
            'device_name' => 'Pixel 10',
            'platform' => 'android',
        ]);

        $loginResponse->assertOk();

        $token = $loginResponse->json('data.token');
        $device = TrustedDevice::query()->where('device_id', 'device-android-1')->firstOrFail();

        $this->withToken($token)->postJson('/api/auth/enable-biometric', [
            'device_id' => 'device-android-1',
            'device_name' => 'Pixel 10',
            'platform' => 'android',
        ])->assertOk()->assertJsonPath('data.device_uuid', 'device-android-1');

        $this->assertDatabaseHas('trusted_devices', [
            'id' => $device->id,
            'biometrics_enabled' => true,
        ]);

        $this->withToken($token)->getJson('/api/auth/devices')
            ->assertOk()
            ->assertJsonPath('data.0.device_uuid', 'device-android-1')
            ->assertJsonPath('data.0.current_device', true);

        $this->withToken($token)->postJson('/api/auth/disable-biometric', [
            'device_id' => 'device-android-1',
        ])->assertOk()->assertJsonPath('data.biometrics_enabled', false);

        $this->assertDatabaseHas('trusted_devices', [
            'id' => $device->id,
            'biometrics_enabled' => false,
        ]);

        $this->withToken($token)->deleteJson("/api/auth/devices/{$device->id}")
            ->assertOk()
            ->assertJsonPath('data.current_device_revoked', true);

        $this->assertNotNull($device->fresh()->revoked_at);
        $this->assertSame(
            0,
            PersonalAccessToken::query()
                ->where('tokenable_type', User::class)
                ->where('name', 'device-android-1')
                ->count()
        );
    }

    public function test_login_accepts_phone_identifier_when_phone_is_registered(): void
    {
        User::query()->create([
            'email' => 'patient.phone@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pho',
            'last_name' => 'Ne',
            'phone' => '+21620000001',
            'role' => 'PATIENT',
        ]);

        $this->postJson('/api/auth/login', [
            'login' => '+216 20 000 001',
            'password' => 'VeryStrongPassword123!',
            'device_id' => 'device-phone-1',
            'device_name' => 'Galaxy S25',
            'platform' => 'android',
        ])->assertOk()->assertJsonPath('success', true);
    }
}
