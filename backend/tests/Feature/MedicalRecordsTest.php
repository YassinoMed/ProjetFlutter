<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MedicalRecordsTest extends TestCase
{
    use RefreshDatabase;

    public function test_doctor_can_create_and_patient_can_list_records(): void
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

        $create = $this->actingAs($doctor, 'api')->postJson('/api/medical-records', [
            'patient_user_id' => $patient->id,
            'category' => 'diagnosis',
            'metadata_encrypted' => ['payload' => 'encrypted'],
            'recorded_at_utc' => '2026-02-20T10:00:00Z',
        ]);

        $create->assertCreated();
        $create->assertJsonPath('record.patient_user_id', $patient->id);
        $create->assertJsonPath('record.doctor_user_id', $doctor->id);

        $list = $this->actingAs($patient, 'api')->getJson('/api/medical-records');
        $list->assertOk();
        $list->assertJsonCount(1, 'data');
        $list->assertJsonPath('data.0.category', 'diagnosis');
    }

    public function test_patient_cannot_override_patient_user_id(): void
    {
        $patient = User::query()->create([
            'email' => 'patient2@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        $response = $this->actingAs($patient, 'api')->postJson('/api/medical-records', [
            'patient_user_id' => '00000000-0000-0000-0000-000000000000',
            'category' => 'notes',
            'metadata_encrypted' => ['payload' => 'encrypted'],
            'recorded_at_utc' => '2026-02-20T10:00:00Z',
        ]);

        $response->assertUnprocessable();
    }
}
