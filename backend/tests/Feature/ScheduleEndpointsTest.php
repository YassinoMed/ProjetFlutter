<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\Doctor;
use App\Models\DoctorSchedule;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ScheduleEndpointsTest extends TestCase
{
    use RefreshDatabase;

    private User $doctor;

    protected function setUp(): void
    {
        parent::setUp();

        $this->doctor = User::factory()->create(['role' => UserRole::DOCTOR]);
        Doctor::query()->create([
            'user_id' => $this->doctor->id,
            'specialty' => 'Cardiologie',
        ]);
    }

    public function test_doctor_can_create_schedule(): void
    {
        Sanctum::actingAs($this->doctor);

        $response = $this->postJson('/api/schedule', [
            'day_of_week' => 1,
            'start_time' => '09:00',
            'end_time' => '12:00',
            'slot_duration_minutes' => 30,
        ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'data' => [
                    'schedule' => ['id', 'day_of_week', 'start_time', 'end_time'],
                ],
            ]);
    }

    public function test_doctor_can_list_schedule(): void
    {
        DoctorSchedule::query()->create([
            'doctor_user_id' => $this->doctor->id,
            'day_of_week' => 1,
            'start_time' => '09:00',
            'end_time' => '12:00',
        ]);

        Sanctum::actingAs($this->doctor);

        $response = $this->getJson('/api/schedule');

        $response->assertOk()
            ->assertJsonStructure(['data']);
    }

    public function test_doctor_can_bulk_update_schedule(): void
    {
        Sanctum::actingAs($this->doctor);

        $response = $this->putJson('/api/schedule/bulk', [
            'slots' => [
                ['day_of_week' => 1, 'start_time' => '09:00', 'end_time' => '12:00'],
                ['day_of_week' => 2, 'start_time' => '14:00', 'end_time' => '17:00'],
            ],
        ]);

        $response->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_patient_cannot_manage_schedule(): void
    {
        $patient = User::factory()->create(['role' => UserRole::PATIENT]);
        Sanctum::actingAs($patient);

        $response = $this->postJson('/api/schedule', [
            'day_of_week' => 1,
            'start_time' => '09:00',
            'end_time' => '12:00',
        ]);

        $response->assertForbidden();
    }
}
