<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\Doctor;
use App\Models\DoctorSchedule;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DoctorSearchTest extends TestCase
{
    use RefreshDatabase;

    private User $patient;

    private User $doctor;

    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        $this->patient = User::factory()->create(['role' => UserRole::PATIENT]);
        $this->doctor = User::factory()->create(['role' => UserRole::DOCTOR]);

        Doctor::query()->create([
            'user_id' => $this->doctor->id,
            'rpps' => 'RPPS000001',
            'specialty' => 'Cardiologie',
            'bio' => 'Expert en cardiologie',
            'consultation_fee' => '60€',
            'city' => 'Paris',
            'rating' => 4.5,
            'total_reviews' => 50,
            'is_available_for_video' => true,
        ]);

        // Create schedule (Monday 09:00-12:00)
        DoctorSchedule::query()->create([
            'doctor_user_id' => $this->doctor->id,
            'day_of_week' => 1,
            'start_time' => '09:00',
            'end_time' => '12:00',
            'slot_duration_minutes' => 30,
            'is_active' => true,
        ]);

        $this->token = auth('api')->login($this->patient);
    }

    public function test_list_doctors(): void
    {
        $response = $this->getJson('/api/doctors', [
            'Authorization' => 'Bearer ' . $this->token,
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'user_id',
                        'first_name',
                        'last_name',
                        'specialty',
                        'city',
                        'rating',
                    ],
                ],
                'next_cursor',
            ]);
    }

    public function test_search_by_specialty(): void
    {
        $response = $this->getJson('/api/doctors?specialty=Cardiologie', [
            'Authorization' => 'Bearer ' . $this->token,
        ]);

        $response->assertOk();
        $data = $response->json('data');
        $this->assertNotEmpty($data);
        $this->assertStringContainsString('Cardiologie', $data[0]['specialty']);
    }

    public function test_search_by_city(): void
    {
        $response = $this->getJson('/api/doctors?city=Paris', [
            'Authorization' => 'Bearer ' . $this->token,
        ]);

        $response->assertOk();
        $data = $response->json('data');
        $this->assertNotEmpty($data);
    }

    public function test_search_by_query(): void
    {
        $response = $this->getJson('/api/doctors?q=' . $this->doctor->first_name, [
            'Authorization' => 'Bearer ' . $this->token,
        ]);

        $response->assertOk();
    }

    public function test_show_doctor(): void
    {
        $response = $this->getJson('/api/doctors/' . $this->doctor->id, [
            'Authorization' => 'Bearer ' . $this->token,
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'doctor' => [
                    'user_id',
                    'first_name',
                    'last_name',
                    'specialty',
                    'bio',
                    'schedules',
                ],
            ]);
    }

    public function test_get_specialties(): void
    {
        $response = $this->getJson('/api/doctors/specialties', [
            'Authorization' => 'Bearer ' . $this->token,
        ]);

        $response->assertOk()
            ->assertJsonStructure(['specialties']);

        $this->assertContains('Cardiologie', $response->json('specialties'));
    }

    public function test_requires_authentication(): void
    {
        $response = $this->getJson('/api/doctors');
        $response->assertUnauthorized();
    }
}
