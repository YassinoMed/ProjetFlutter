<?php

namespace Tests\Feature;

use App\Events\CallSessionAccepted;
use App\Events\CallSessionEnded;
use App\Events\CallSessionRejected;
use App\Events\CallSessionRinging;
use App\Events\CallSessionTimedOut;
use App\Events\TeleconsultationUpdated;
use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\DoctorSecretaryDelegation;
use App\Models\Teleconsultation;
use App\Models\User;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class TeleconsultationEndpointsTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
        Event::fake([
            CallSessionAccepted::class,
            CallSessionEnded::class,
            CallSessionRejected::class,
            CallSessionRinging::class,
            CallSessionTimedOut::class,
            TeleconsultationUpdated::class,
        ]);
        Notification::fake();
        Queue::fake();
    }

    public function test_patient_authorized_can_join_started_teleconsultation(): void
    {
        [$doctor, $patient, $teleconsultation] = $this->createTeleconsultation();

        $this->startTeleconsultation($doctor, $teleconsultation);

        Sanctum::actingAs($patient);

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/join", [
            'camera_enabled' => true,
            'microphone_enabled' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.teleconsultation.status', 'active')
            ->assertJsonPath('data.self_user_id', $patient->id);
    }

    public function test_patient_not_assigned_cannot_join_teleconsultation(): void
    {
        [$doctor, , $teleconsultation] = $this->createTeleconsultation();
        $intruder = User::factory()->create(['role' => 'PATIENT']);

        $this->startTeleconsultation($doctor, $teleconsultation);

        Sanctum::actingAs($intruder);

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/join")
            ->assertForbidden();
    }

    public function test_authorized_doctor_can_start_teleconsultation(): void
    {
        [$doctor, , $teleconsultation] = $this->createTeleconsultation();

        $this->startTeleconsultation($doctor, $teleconsultation)
            ->assertOk()
            ->assertJsonPath('data.teleconsultation.status', 'waiting');
    }

    public function test_unassigned_doctor_cannot_start_teleconsultation(): void
    {
        [, , $teleconsultation] = $this->createTeleconsultation();
        $otherDoctor = User::factory()->create(['role' => 'DOCTOR']);

        Sanctum::actingAs($otherDoctor);

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/start", [
            'call_type' => 'VIDEO',
        ])->assertForbidden();
    }

    public function test_double_active_call_for_same_consultation_is_rejected(): void
    {
        [$doctor, , $teleconsultation] = $this->createTeleconsultation();
        $this->startTeleconsultation($doctor, $teleconsultation);

        $teleconsultation = $teleconsultation->fresh();

        Sanctum::actingAs($doctor);

        $this->postJson('/api/calls/initiate', [
            'conversation_id' => $teleconsultation->conversation_id,
            'consultation_id' => $teleconsultation->appointment_id,
            'call_type' => 'VIDEO',
        ])->assertStatus(409);
    }

    public function test_expired_call_is_not_joinable(): void
    {
        [$doctor, $patient, $teleconsultation] = $this->createTeleconsultation();
        $this->startTeleconsultation($doctor, $teleconsultation);

        $teleconsultation = $teleconsultation->fresh();
        CallSession::query()
            ->whereKey($teleconsultation->current_call_session_id)
            ->update(['expires_at_utc' => now('UTC')->subMinute()]);

        Sanctum::actingAs($patient);

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/join")
            ->assertStatus(409);

        $this->assertDatabaseHas('teleconsultations', [
            'id' => $teleconsultation->id,
            'status' => 'expired',
        ]);
    }

    public function test_ended_teleconsultation_cannot_be_restarted(): void
    {
        [$doctor, $patient, $teleconsultation] = $this->createTeleconsultation();
        $this->startTeleconsultation($doctor, $teleconsultation);

        Sanctum::actingAs($patient);
        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/join")->assertOk();

        Sanctum::actingAs($doctor);
        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/end")
            ->assertOk()
            ->assertJsonPath('data.teleconsultation.status', 'ended');

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/start", [
            'call_type' => 'VIDEO',
        ])->assertStatus(409);
    }

    public function test_scheduled_teleconsultation_can_be_cancelled(): void
    {
        [, $patient, $teleconsultation] = $this->createTeleconsultation();

        Sanctum::actingAs($patient);

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/cancel", [
            'reason' => 'Patient unavailable',
        ])
            ->assertOk()
            ->assertJsonPath('data.teleconsultation.status', 'cancelled');
    }

    public function test_active_teleconsultation_can_be_ended_by_doctor(): void
    {
        [$doctor, $patient, $teleconsultation] = $this->createTeleconsultation();
        $this->startTeleconsultation($doctor, $teleconsultation);

        Sanctum::actingAs($patient);
        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/join")->assertOk();

        Sanctum::actingAs($doctor);

        $this->postJson("/api/teleconsultations/{$teleconsultation->id}/end", [
            'reason' => 'completed',
        ])
            ->assertOk()
            ->assertJsonPath('data.teleconsultation.status', 'ended');
    }

    public function test_secretary_without_permission_is_blocked_from_teleconsultations(): void
    {
        [$doctor] = $this->createTeleconsultation();
        $secretary = User::factory()->create(['role' => 'SECRETARY']);

        DoctorSecretaryDelegation::query()->create([
            'doctor_user_id' => $doctor->id,
            'secretary_user_id' => $secretary->id,
            'invited_by_user_id' => $doctor->id,
            'invited_email' => $secretary->email,
            'status' => 'ACTIVE',
            'activated_at_utc' => now('UTC'),
        ]);

        Sanctum::actingAs($secretary);

        $this->getJson('/api/teleconsultations', ['X-Acting-Doctor-Id' => $doctor->id])
            ->assertForbidden();
    }

    private function createTeleconsultation(): array
    {
        $patient = User::factory()->create(['role' => 'PATIENT']);
        $doctor = User::factory()->create(['role' => 'DOCTOR']);

        $appointment = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => now('UTC')->addHour(),
            'ends_at_utc' => now('UTC')->addMinutes(90),
            'status' => 'CONFIRMED',
        ]);

        Sanctum::actingAs($doctor);

        $response = $this->postJson('/api/teleconsultations', [
            'appointment_id' => $appointment->id,
            'call_type' => 'VIDEO',
        ])->assertCreated();

        $teleconsultation = Teleconsultation::query()->findOrFail(
            $response->json('data.teleconsultation.id'),
        );

        return [$doctor, $patient, $teleconsultation, $appointment];
    }

    private function startTeleconsultation(User $doctor, Teleconsultation $teleconsultation): \Illuminate\Testing\TestResponse
    {
        Sanctum::actingAs($doctor);

        return $this->postJson("/api/teleconsultations/{$teleconsultation->id}/start", [
            'call_type' => 'VIDEO',
        ]);
    }
}
