<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\DoctorSchedule;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class DoctorSecretaryDelegationTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
    }

    public function test_doctor_can_invite_and_secretary_can_accept_with_permissions(): void
    {
        $doctor = User::factory()->create([
            'role' => 'DOCTOR',
            'email' => 'doctor.secretary@example.test',
        ]);

        Sanctum::actingAs($doctor);

        $inviteResponse = $this->postJson('/api/doctor/secretaries/invite', [
            'email' => 'secretary@example.test',
            'first_name' => 'Sara',
            'last_name' => 'Desk',
            'permissions' => [
                'MANAGE_APPOINTMENTS',
                'MANAGE_SCHEDULE',
            ],
            'expires_in_hours' => 24,
        ]);

        $inviteResponse->assertCreated();
        $inviteResponse->assertJsonPath('data.delegation.status', 'PENDING');
        $inviteResponse->assertJsonPath('data.delegation.invited_email', 'secretary@example.test');

        $token = $inviteResponse->json('data.invitation_token');

        $acceptResponse = $this->postJson('/api/secretary/invitations/accept', [
            'token' => $token,
            'first_name' => 'Sara',
            'last_name' => 'Desk',
            'password' => 'VeryStrongPassword123!',
            'phone' => '+21620000001',
        ]);

        $acceptResponse->assertOk();
        $acceptResponse->assertJsonPath('data.delegation.status', 'ACTIVE');
        $acceptResponse->assertJsonPath('data.delegation.secretary.email', 'secretary@example.test');

        $secretary = User::query()->where('email', 'secretary@example.test')->firstOrFail();

        $this->assertSame('SECRETARY', $secretary->role->value);
        $this->assertDatabaseHas('doctor_secretary_delegations', [
            'doctor_user_id' => $doctor->id,
            'secretary_user_id' => $secretary->id,
            'status' => 'ACTIVE',
        ]);
        $this->assertDatabaseHas('doctor_secretary_permissions', [
            'permission' => 'MANAGE_APPOINTMENTS',
        ]);
        $this->assertDatabaseHas('secretary_invitations', [
            'email' => 'secretary@example.test',
            'status' => 'ACCEPTED',
        ]);
    }

    public function test_secretary_can_manage_doctor_scope_with_explicit_context_and_audit(): void
    {
        $doctor = User::factory()->create([
            'role' => 'DOCTOR',
            'email' => 'dr.context@example.test',
        ]);
        $patient = User::factory()->create([
            'role' => 'PATIENT',
            'email' => 'patient.context@example.test',
        ]);

        $inviteToken = $this->inviteSecretaryAndAccept($doctor, 'context.secretary@example.test');
        $secretary = User::query()->where('email', 'context.secretary@example.test')->firstOrFail();

        $schedule = DoctorSchedule::query()->create([
            'doctor_user_id' => $doctor->id,
            'day_of_week' => 1,
            'start_time' => '09:00',
            'end_time' => '12:00',
            'slot_duration_minutes' => 30,
            'is_active' => true,
        ]);

        $appointment = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-11 09:00:00',
            'ends_at_utc' => '2026-03-11 09:30:00',
            'status' => 'REQUESTED',
        ]);

        Sanctum::actingAs($secretary);

        $headers = ['X-Acting-Doctor-Id' => $doctor->id];

        $this->postJson('/api/context/switch-doctor', [
            'doctor_user_id' => $doctor->id,
        ])->assertOk();

        $appointmentsResponse = $this->getJson('/api/appointments', $headers);
        $appointmentsResponse->assertOk();
        $appointmentsResponse->assertJsonPath('data.0.id', $appointment->id);

        $scheduleResponse = $this->getJson('/api/schedule', $headers);
        $scheduleResponse->assertOk();
        $scheduleResponse->assertJsonPath('data.0.id', $schedule->id);

        $confirmResponse = $this->postJson("/api/appointments/{$appointment->id}/confirm", [], $headers);
        $confirmResponse->assertOk();
        $confirmResponse->assertJsonPath('data.appointment.status', 'CONFIRMED');

        $this->assertDatabaseHas('audit_logs', [
            'actor_user_id' => $secretary->id,
            'actor_role' => 'SECRETARY',
            'acting_doctor_user_id' => $doctor->id,
            'event' => 'appointment.confirmed',
        ]);
        $this->assertDatabaseHas('audit_logs', [
            'actor_user_id' => $secretary->id,
            'actor_role' => 'SECRETARY',
            'acting_doctor_user_id' => $doctor->id,
            'event' => 'schedule.viewed',
        ]);

        $this->assertDatabaseHas('appointments', [
            'id' => $appointment->id,
            'status' => 'CONFIRMED',
        ]);
    }

    public function test_suspended_secretary_loses_access_immediately(): void
    {
        $doctor = User::factory()->create(['role' => 'DOCTOR']);
        $this->inviteSecretaryAndAccept($doctor, 'suspended.secretary@example.test');
        $secretary = User::query()->where('email', 'suspended.secretary@example.test')->firstOrFail();

        $delegationId = \App\Models\DoctorSecretaryDelegation::query()
            ->where('doctor_user_id', $doctor->id)
            ->where('secretary_user_id', $secretary->id)
            ->value('id');

        Sanctum::actingAs($doctor);
        $this->patchJson("/api/doctor/secretaries/{$delegationId}/suspend", [
            'reason' => 'Policy review',
        ])->assertOk();

        Sanctum::actingAs($secretary);
        $this->getJson('/api/schedule', ['X-Acting-Doctor-Id' => $doctor->id])
            ->assertForbidden();
    }

    private function inviteSecretaryAndAccept(User $doctor, string $email): string
    {
        Sanctum::actingAs($doctor);

        $token = $this->postJson('/api/doctor/secretaries/invite', [
            'email' => $email,
            'first_name' => 'Sec',
            'last_name' => 'Retary',
            'permissions' => [
                'MANAGE_APPOINTMENTS',
                'MANAGE_SCHEDULE',
            ],
        ])->json('data.invitation_token');

        $this->postJson('/api/secretary/invitations/accept', [
            'token' => $token,
            'first_name' => 'Sec',
            'last_name' => 'Retary',
            'password' => 'VeryStrongPassword123!',
        ])->assertOk();

        return $token;
    }
}
