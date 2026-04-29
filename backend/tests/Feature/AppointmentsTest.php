<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\DoctorSecretaryDelegation;
use App\Models\DoctorSecretaryPermission;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
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

        Sanctum::actingAs($patient);

        $create = $this->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2030-03-01T10:00:00Z',
            'ends_at_utc' => '2030-03-01T10:30:00Z',
        ]);

        $create->assertCreated();
        $appointmentId = $create->json('data.appointment.id');

        Sanctum::actingAs($doctor);

        $confirm = $this->postJson("/api/appointments/{$appointmentId}/confirm");
        $confirm->assertOk();
        $confirm->assertJsonPath('data.appointment.status', 'CONFIRMED');
    }

    public function test_patient_can_cancel_requested_appointment_before_secretary_confirmation(): void
    {
        [$patient, $doctor, $appointment] = $this->createRequestedAppointment();

        Sanctum::actingAs($patient);

        $this
            ->postJson("/api/appointments/{$appointment->id}/cancel", [
                'cancel_reason' => 'Patient unavailable',
            ])
            ->assertOk()
            ->assertJsonPath('data.appointment.status', 'CANCELLED')
            ->assertJsonPath('data.appointment.cancel_reason', 'Patient unavailable');

        $this->assertDatabaseHas('appointments', [
            'id' => $appointment->id,
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'status' => 'CANCELLED',
        ]);
    }

    public function test_patient_cannot_cancel_after_secretary_or_doctor_confirmation(): void
    {
        [$patient, , $appointment] = $this->createRequestedAppointment();

        $appointment->forceFill(['status' => 'CONFIRMED'])->save();

        Sanctum::actingAs($patient);

        $this
            ->postJson("/api/appointments/{$appointment->id}/cancel")
            ->assertStatus(409);
    }

    public function test_delegated_secretary_can_accept_pending_appointment(): void
    {
        [, $doctor, $appointment] = $this->createRequestedAppointment();
        [$secretary] = $this->createSecretaryDelegation($doctor);

        Sanctum::actingAs($secretary);

        $this
            ->postJson(
                "/api/appointments/{$appointment->id}/confirm",
                [],
                ['X-Acting-Doctor-Id' => $doctor->id],
            )
            ->assertOk()
            ->assertJsonPath('data.appointment.status', 'CONFIRMED');
    }

    public function test_delegated_secretary_can_reject_pending_appointment(): void
    {
        [, $doctor, $appointment] = $this->createRequestedAppointment();
        [$secretary] = $this->createSecretaryDelegation($doctor);

        Sanctum::actingAs($secretary);

        $this
            ->postJson(
                "/api/appointments/{$appointment->id}/reject",
                ['cancel_reason' => 'Slot not available'],
                ['X-Acting-Doctor-Id' => $doctor->id],
            )
            ->assertOk()
            ->assertJsonPath('data.appointment.status', 'CANCELLED')
            ->assertJsonPath('data.appointment.cancel_reason', 'Slot not available');
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

        Sanctum::actingAs($patient);

        $this->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2030-03-01T10:00:00Z',
            'ends_at_utc' => '2030-03-01T10:30:00Z',
        ])->assertCreated();

        Sanctum::actingAs($patient2);

        $this->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2030-03-01T10:15:00Z',
            'ends_at_utc' => '2030-03-01T10:45:00Z',
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

        Sanctum::actingAs($doctor);

        $this->postJson('/api/appointments', [
            'doctor_user_id' => $targetDoctor->id,
            'starts_at_utc' => '2030-03-01T12:00:00Z',
            'ends_at_utc' => '2030-03-01T12:30:00Z',
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

        Sanctum::actingAs($patient);

        $this->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2030-03-01T10:30:00Z',
            'ends_at_utc' => '2030-03-01T10:00:00Z',
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

        Sanctum::actingAs($patient);

        $appointment = $this->postJson('/api/appointments', [
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2030-03-01T11:00:00Z',
            'ends_at_utc' => '2030-03-01T11:30:00Z',
        ])->json('data.appointment.id');

        Sanctum::actingAs($admin);

        $this
            ->getJson('/api/appointments')
            ->assertOk()
            ->assertJsonFragment(['id' => $appointment]);
    }

    private function createRequestedAppointment(): array
    {
        $patient = User::query()->create([
            'email' => 'patient-'.str()->uuid().'@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $doctor = User::query()->create([
            'email' => 'doctor-'.str()->uuid().'@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc',
            'last_name' => 'Tor',
            'role' => 'DOCTOR',
        ]);

        $appointment = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => now('UTC')->addDays(2),
            'ends_at_utc' => now('UTC')->addDays(2)->addMinutes(30),
            'status' => 'REQUESTED',
        ]);

        return [$patient, $doctor, $appointment];
    }

    private function createSecretaryDelegation(User $doctor): array
    {
        $secretary = User::query()->create([
            'email' => 'secretary-'.str()->uuid().'@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Sec',
            'last_name' => 'Retary',
            'role' => 'SECRETARY',
        ]);

        $delegation = DoctorSecretaryDelegation::query()->create([
            'doctor_user_id' => $doctor->id,
            'secretary_user_id' => $secretary->id,
            'invited_by_user_id' => $doctor->id,
            'invited_email' => $secretary->email,
            'status' => 'ACTIVE',
            'activated_at_utc' => now('UTC'),
        ]);

        DoctorSecretaryPermission::query()->create([
            'delegation_id' => $delegation->id,
            'permission' => 'MANAGE_APPOINTMENTS',
        ]);

        return [$secretary, $delegation];
    }
}
