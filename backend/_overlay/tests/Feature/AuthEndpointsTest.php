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
            'first_name' => 'Pat',
            'last_name' => 'Ient',
        ]);

        $response->assertCreated();
        $response->assertJsonPath('user.email', 'patient@example.com');
        $response->assertJsonStructure([
            'user' => ['id', 'email', 'first_name', 'last_name', 'role'],
            'tokens' => ['access_token', 'refresh_token', 'token_type'],
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
        $response->assertJsonStructure(['tokens' => ['access_token', 'refresh_token']]);
    }

    public function test_me_requires_auth(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();
    }
}
