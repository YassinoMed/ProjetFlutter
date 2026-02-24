<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Models\FcmToken;
use App\Models\User;
use App\Models\UserConsent;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RgpdEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_manage_rgpd_flow(): void
    {
        $patient = User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $doctor = User::query()->create([
            'email' => 'doctor@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc',
            'last_name' => 'Tor',
            'role' => 'DOCTOR',
        ]);

        $appointment = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-02-20T10:00:00Z',
            'ends_at_utc' => '2026-02-20T10:30:00Z',
            'status' => 'CONFIRMED',
        ]);

        ChatMessage::query()->create([
            'consultation_id' => $appointment->id,
            'sender_user_id' => $patient->id,
            'recipient_user_id' => $doctor->id,
            'ciphertext' => 'ciphertext',
            'nonce' => 'nonce',
            'algorithm' => 'xchacha20poly1305',
            'sent_at_utc' => now('UTC'),
        ]);

        FcmToken::query()->create([
            'user_id' => $patient->id,
            'token' => 'token_12345678901234567890',
            'platform' => 'ios',
            'last_seen_at_utc' => now('UTC'),
        ]);

        UserConsent::query()->create([
            'user_id' => $patient->id,
            'consent_type' => 'privacy',
            'consented' => true,
            'consented_at_utc' => now('UTC'),
        ]);

        $consent = $this->actingAs($patient, 'api')->postJson('/api/rgpd/consent', [
            'consent_type' => 'marketing',
            'consented' => false,
        ]);

        $consent->assertOk();
        $consent->assertJsonPath('ok', true);

        $export = $this->actingAs($patient, 'api')->getJson('/api/rgpd/export');
        $export->assertOk();
        $export->assertJsonStructure([
            'user',
            'appointments',
            'chat_messages',
            'fcm_tokens',
            'consents',
            'exported_at_utc',
        ]);

        $forget = $this->actingAs($patient, 'api')->deleteJson('/api/rgpd/forget');
        $forget->assertOk();
        $forget->assertJsonPath('ok', true);

        $this->assertDatabaseMissing('fcm_tokens', [
            'user_id' => $patient->id,
        ]);
    }
}
