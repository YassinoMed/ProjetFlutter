<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\User;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class TeleconsultationSchemaGuardTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
    }

    public function test_it_returns_a_controlled_error_when_teleconsultation_tables_are_missing(): void
    {
        Schema::dropIfExists('call_events');
        Schema::dropIfExists('teleconsultation_participants');
        Schema::dropIfExists('teleconsultations');

        $patient = User::factory()->create(['role' => 'PATIENT']);
        $doctor = User::factory()->create(['role' => 'DOCTOR']);

        $appointment = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => now('UTC')->addDay(),
            'ends_at_utc' => now('UTC')->addDay()->addMinutes(30),
            'status' => 'CONFIRMED',
        ]);

        Sanctum::actingAs($doctor);

        $this->postJson('/api/teleconsultations', [
            'appointment_id' => $appointment->id,
            'call_type' => 'VIDEO',
        ])
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Teleconsultation is temporarily unavailable for this tenant.')
            ->assertJsonPath('error.code', 503);
    }
}
