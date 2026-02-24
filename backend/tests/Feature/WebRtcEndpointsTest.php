<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WebRtcEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_send_webrtc_signaling_events(): void
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
            'starts_at_utc' => '2026-03-01T10:00:00Z',
            'ends_at_utc' => '2026-03-01T10:30:00Z',
            'status' => 'CONFIRMED',
        ]);

        $this->actingAs($patient, 'api')
            ->postJson("/api/consultations/{$appointment->id}/webrtc/join")
            ->assertOk()
            ->assertJsonPath('ok', true);

        $this->actingAs($patient, 'api')
            ->postJson("/api/consultations/{$appointment->id}/webrtc/offer", [
                'sdp' => 'v=0',
                'sdp_type' => 'offer',
            ])
            ->assertOk()
            ->assertJsonPath('ok', true);

        $this->actingAs($doctor, 'api')
            ->postJson("/api/consultations/{$appointment->id}/webrtc/answer", [
                'sdp' => 'v=0',
                'sdp_type' => 'answer',
            ])
            ->assertOk()
            ->assertJsonPath('ok', true);

        $this->actingAs($patient, 'api')
            ->postJson("/api/consultations/{$appointment->id}/webrtc/ice", [
                'candidate' => 'candidate:0 1 UDP 2122252543 192.0.2.1 54400 typ host',
                'sdp_mid' => '0',
                'sdp_mline_index' => 0,
            ])
            ->assertOk()
            ->assertJsonPath('ok', true);
    }
}
