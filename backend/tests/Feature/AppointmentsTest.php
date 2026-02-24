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
            'starts_at_utc' => '2026-03-01T10:00:00Z',
            'ends_at_utc' => '2026-03-01T10:30:00Z',
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
            'starts_at_utc' => '2026-03-01T10:00:00Z',
            'ends_at_utc' => '2026-03-01T10:30:00Z',
        ])->assertCreated();

        $this->actingAs($patient2, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-01T10:15:00Z',
            'ends_at_utc' => '2026-03-01T10:45:00Z',
        ])->assertUnprocessable();
    }

    public function test_doctor_cannot_create_appointment(): void
    {
        $doctor = User::query()->create([
            'email' => 'doctor@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc',
            'last_name' => 'Tor',
            'role' => 'DOCTOR',
        ]);

        $targetDoctor = User::query()->create([
            'email' => 'doctor2@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc2',
            'last_name' => 'Tor2',
            'role' => 'DOCTOR',
        ]);

        $this->actingAs($doctor, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $targetDoctor->id,
            'starts_at_utc' => '2026-03-01T12:00:00Z',
            'ends_at_utc' => '2026-03-01T12:30:00Z',
        ])->assertForbidden();
    }

    public function test_invalid_dates_are_rejected(): void
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

        $this->actingAs($patient, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-01T10:30:00Z',
            'ends_at_utc' => '2026-03-01T10:00:00Z',
        ])->assertUnprocessable();
    }

    public function test_admin_can_list_all_appointments(): void
    {
        $admin = User::query()->create([
            'email' => 'admin@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Admin',
            'last_name' => 'User',
            'role' => 'ADMIN',
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

        $appointment = $this->actingAs($patient, 'api')->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-01T11:00:00Z',
            'ends_at_utc' => '2026-03-01T11:30:00Z',
        ])->json('appointment.id');

        $this->actingAs($admin, 'api')
            ->getJson('/api/appointments')
            ->assertOk()
            ->assertJsonFragment(['id' => $appointment]);
    }
}
