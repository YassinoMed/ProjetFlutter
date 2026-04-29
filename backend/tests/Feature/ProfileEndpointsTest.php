<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_patient_can_update_profile(): void
    {
        $patient = User::query()->create([
            'email' => 'patient@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Pat',
            'last_name' => 'Ient',
            'role' => 'PATIENT',
        ]);

        Sanctum::actingAs($patient);

        $response = $this->putJson('/api/profile', [
            'phone' => '+33123456789',
            'date_of_birth' => '1990-01-01',
            'sex' => 'F',
        ]);

        $response->assertOk();
        $response->assertJsonPath('data.user.phone', '+33123456789');
        $response->assertJsonPath('data.patient_profile.date_of_birth', '1990-01-01');
        $response->assertJsonPath('data.patient_profile.sex', 'F');
        $response->assertJsonPath('data.doctor_profile', null);

        Sanctum::actingAs($patient);

        $show = $this->getJson('/api/profile');
        $show->assertOk();
        $show->assertJsonPath('data.patient_profile.date_of_birth', '1990-01-01');
    }

    public function test_doctor_can_update_profile(): void
    {
        $doctor = User::query()->create([
            'email' => 'doctor@example.com',
            'password' => 'VeryStrongPassword123!',
            'first_name' => 'Doc',
            'last_name' => 'Tor',
            'role' => 'DOCTOR',
        ]);

        Sanctum::actingAs($doctor);

        $response = $this->putJson('/api/profile', [
            'rpps' => 'RPPS-123456',
            'specialty' => 'Cardiologie',
        ]);

        $response->assertOk();
        $response->assertJsonPath('data.doctor_profile.rpps', 'RPPS-123456');
        $response->assertJsonPath('data.doctor_profile.specialty', 'Cardiologie');
        $response->assertJsonPath('data.patient_profile', null);
    }
}
