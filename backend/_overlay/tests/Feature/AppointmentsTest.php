<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AppointmentsTest extends TestCase
{
    use RefreshDatabase;

    public function test_patient_can_create_appointment_and_doctor_can_confirm(): void
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

        $create = $this->actingAs($patient, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-02-20T10:00:00Z',
            'ends_at_utc' => '2026-02-20T10:30:00Z',
        ]);

        $create->assertCreated();
        $appointmentId = $create->json('appointment.id');

        $confirm = $this->actingAs($doctor, 'api')->postJson("/api/appointments/{$appointmentId}/confirm");
        $confirm->assertOk();
        $confirm->assertJsonPath('appointment.status', 'CONFIRMED');
    }

    public function test_doctor_overlap_is_rejected_atomically(): void
    {
        $patient = User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $patient2 = User::query()->create([
            'email' => 'patient2@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat2',
            'last_name' => 'Ient2',
            'role' => 'PATIENT',
        ]);

        $doctor = User::query()->create([
            'email' => 'doctor@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc',
            'last_name' => 'Tor',
            'role' => 'DOCTOR',
        ]);

        $this->actingAs($patient, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-02-20T10:00:00Z',
            'ends_at_utc' => '2026-02-20T10:30:00Z',
        ])->assertCreated();

        $this->actingAs($patient2, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-02-20T10:15:00Z',
            'ends_at_utc' => '2026-02-20T10:45:00Z',
        ])->assertUnprocessable();
    }
}
