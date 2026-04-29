<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\Doctor;
use App\Models\DoctorSchedule;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DoctorSearchTest extends TestCase
{
    use RefreshDatabase;

    private User $patient;

    private User $doctor;

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
    }

    public function test_list_doctors(): void
    {
        Sanctum::actingAs($this->patient);

        $response = $this->getJson('/api/doctors');

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
                'meta' => ['next_cursor'],
            ]);
    }

    public function test_search_by_specialty(): void
    {
        Sanctum::actingAs($this->patient);

        $response = $this->getJson('/api/doctors?specialty=Cardiologie');

        $response->assertOk();
        $data = $response->json('data');
        $this->assertNotEmpty($data);
        $this->assertStringContainsString('Cardiologie', $data[0]['specialty']);
    }

    public function test_search_by_city(): void
    {
        Sanctum::actingAs($this->patient);

        $response = $this->getJson('/api/doctors?city=Paris');

        $response->assertOk();
        $data = $response->json('data');
        $this->assertNotEmpty($data);
    }

    public function test_search_by_query(): void
    {
        Sanctum::actingAs($this->patient);

        $response = $this->getJson('/api/doctors?q='.$this->doctor->first_name);

        $response->assertOk();
    }

    public function test_show_doctor(): void
    {
        Sanctum::actingAs($this->patient);

        $response = $this->getJson('/api/doctors/'.$this->doctor->id);

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'doctor' => [
                        'user_id',
                        'first_name',
                        'last_name',
                        'specialty',
                        'bio',
                        'schedules',
                    ],
                ],
            ]);
    }

    public function test_get_specialties(): void
    {
        Sanctum::actingAs($this->patient);

        $response = $this->getJson('/api/doctors/specialties');

        $response->assertOk()
            ->assertJsonStructure(['data' => ['specialties']]);

        $this->assertContains('Cardiologie', $response->json('data.specialties'));
    }

    public function test_requires_authentication(): void
    {
        $response = $this->getJson('/api/doctors');
        $response->assertUnauthorized();
    }
}
