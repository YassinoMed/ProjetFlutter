<?php

namespace Tests\Feature;

use App\Events\ConsultationJoined;
use App\Events\WebRtcAnswerSent;
use App\Events\WebRtcIceCandidateSent;
use App\Events\WebRtcOfferSent;
use App\Models\Appointment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WebRtcEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_send_webrtc_signaling_events(): void
    {
        Event::fake([
            ConsultationJoined::class,
            WebRtcAnswerSent::class,
            WebRtcIceCandidateSent::class,
            WebRtcOfferSent::class,
        ]);

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
            'starts_at_utc' => '2026-03-01T10:00:00Z',
            'ends_at_utc' => '2026-03-01T10:30:00Z',
            'status' => 'CONFIRMED',
        ]);

        Sanctum::actingAs($patient);

        $this->postJson("/api/consultations/{$appointment->id}/webrtc/join")
            ->assertOk()
            ->assertJsonPath('success', true);

        Sanctum::actingAs($patient);

        $this->postJson("/api/consultations/{$appointment->id}/webrtc/offer", [
            'sdp' => 'v=0',
            'sdp_type' => 'offer',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        Sanctum::actingAs($doctor);

        $this->postJson("/api/consultations/{$appointment->id}/webrtc/answer", [
            'sdp' => 'v=0',
            'sdp_type' => 'answer',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        Sanctum::actingAs($patient);

        $this->postJson("/api/consultations/{$appointment->id}/webrtc/ice", [
            'candidate' => 'candidate:0 1 UDP 2122252543 192.0.2.1 54400 typ host',
            'sdp_mid' => '0',
            'sdp_mline_index' => 0,
        ])
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_authenticated_user_receives_ephemeral_turn_credentials(): void
    {
        config()->set('webrtc.stun_urls', 'stun:stun.example.test:3478');
        config()->set('webrtc.turn_urls', 'turn:turn.example.test:3478?transport=udp,turns:turn.example.test:5349?transport=tcp');
        config()->set('webrtc.shared_secret', 'test-turn-shared-secret');
        config()->set('webrtc.credential_ttl_seconds', 900);

        $patient = User::query()->create([
            'email' => 'turn-patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Turn',
            'role' => 'PATIENT',
        ]);

        Sanctum::actingAs($patient);

        $response = $this->getJson('/api/webrtc/ice-servers')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.credential_mode', 'ephemeral_hmac')
            ->assertJsonPath('data.ice_servers.0.urls', 'stun:stun.example.test:3478')
            ->assertJsonPath('data.ice_servers.1.urls.0', 'turn:turn.example.test:3478?transport=udp')
            ->assertJsonPath('data.ice_servers.1.urls.1', 'turns:turn.example.test:5349?transport=tcp');

        $username = $response->json('data.ice_servers.1.username');
        $credential = $response->json('data.ice_servers.1.credential');

        $this->assertStringEndsWith(':'.$patient->id, $username);
        $this->assertSame(
            base64_encode(hash_hmac('sha1', $username, 'test-turn-shared-secret', true)),
            $credential,
        );
    }
}
