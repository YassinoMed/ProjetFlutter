<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_creates_user_and_returns_tokens(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'password_confirmation' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
        ]);

        $response->assertCreated();
        $response->assertJsonPath('data.user.email', 'patient@example.com');
        $response->assertJsonStructure([
            'data' => [
                'user' => ['id', 'email', 'first_name', 'last_name', 'role'],
                'token',
            ],
        ]);

        $this->assertDatabaseCount('users', 1);
    }

    public function test_login_returns_tokens(): void
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
        ]);

        $response->assertOk();
        $response->assertJsonStructure(['data' => ['user', 'token', 'device_approved']]);
    }

    public function test_me_requires_auth(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();
    }
}
