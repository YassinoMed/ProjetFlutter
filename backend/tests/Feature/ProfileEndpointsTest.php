<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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

        $response = $this->actingAs($patient, 'api')->putJson('/api/profile', [
            'phone' => '+33123456789',
            'date_of_birth' => '1990-01-01',
            'sex' => 'F',
        ]);

        $response->assertOk();
        $response->assertJsonPath('user.phone', '+33123456789');
        $response->assertJsonPath('patient_profile.date_of_birth', '1990-01-01');
        $response->assertJsonPath('patient_profile.sex', 'F');
        $response->assertJsonPath('doctor_profile', null);

        $show = $this->actingAs($patient, 'api')->getJson('/api/profile');
        $show->assertOk();
        $show->assertJsonPath('patient_profile.date_of_birth', '1990-01-01');
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

        $response = $this->actingAs($doctor, 'api')->putJson('/api/profile', [
            'rpps' => 'RPPS-123456',
            'specialty' => 'Cardiologie',
        ]);

        $response->assertOk();
        $response->assertJsonPath('doctor_profile.rpps', 'RPPS-123456');
        $response->assertJsonPath('doctor_profile.specialty', 'Cardiologie');
        $response->assertJsonPath('patient_profile', null);
    }
}
