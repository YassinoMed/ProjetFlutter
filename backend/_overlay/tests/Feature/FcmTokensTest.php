<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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

        $token = 'token_12345678901234567890';

        $this->actingAs($user, 'api')
            ->postJson('/api/fcm/tokens', ['token' => $token, 'platform' => 'ios'])
            ->assertOk()
            ->assertJsonPath('ok', true);

        $this->assertDatabaseHas('fcm_tokens', [
            'user_id' => $user->id,
            'token' => $token,
            'platform' => 'ios',
        ]);

        $this->actingAs($user, 'api')
            ->deleteJson('/api/fcm/tokens', ['token' => $token])
            ->assertOk()
            ->assertJsonPath('ok', true);

        $this->assertDatabaseMissing('fcm_tokens', [
            'user_id' => $user->id,
            'token' => $token,
        ]);
    }
}
