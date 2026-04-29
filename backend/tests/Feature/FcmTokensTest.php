<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FcmTokensTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_upsert_and_delete_fcm_token(): void
    {
        $user = User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $token = 'fcm-test-token-user-upsert';

        Sanctum::actingAs($user);

        $this->postJson('/api/fcm/tokens', ['token' => $token, 'platform' => 'ios'])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('fcm_tokens', [
            'user_id' => $user->id,
            'token' => $token,
            'platform' => 'ios',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson('/api/fcm/tokens', ['token' => $token])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.deleted', 1);

        $this->assertDatabaseMissing('fcm_tokens', [
            'user_id' => $user->id,
            'token' => $token,
        ]);
    }
}
