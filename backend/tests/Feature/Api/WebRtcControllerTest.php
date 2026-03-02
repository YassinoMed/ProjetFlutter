<?php

namespace Tests\Feature\Api;

use App\Events\ConsultationJoined;
use App\Events\WebRtcOfferSent;
use App\Events\WebRtcAnswerSent;
use App\Events\WebRtcIceCandidateSent;
use App\Models\Appointment;
use App\Models\User;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Tests\TestCase;
use Illuminate\Support\Str;
use Mockery\MockInterface;

class WebRtcControllerTest extends TestCase
{
    private User $patient;
    private User $doctor;
    private Appointment $appointment;

    protected function setUp(): void
    {
        parent::setUp();
        
        if (!Schema::hasTable('tenants')) {
            Schema::create('tenants', function (Blueprint $table) {
                $table->string('id')->primary();
                $table->string('name')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                $table->json('data')->nullable();
            });
            \Illuminate\Support\Facades\Event::fake();
            \App\Models\Tenant::create(['id' => 'tenant1', 'name' => 'Demo Tenant']);
        }

        // Manual schema creation for in-memory SQLite to bypass tenancy migration issues
        if (!Schema::hasTable('users')) {
            Schema::create('users', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->string('email');
                $table->string('password');
                $table->string('first_name')->nullable();
                $table->string('last_name')->nullable();
                $table->string('phone')->nullable();
                $table->timestamp('email_verified_at')->nullable();
                $table->string('remember_token')->nullable();
                $table->string('role')->nullable();
                $table->boolean('is_active')->default(true);
                $table->string('stripe_customer_id')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('appointments')) {
            Schema::create('appointments', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('patient_user_id');
                $table->uuid('doctor_user_id');
                $table->string('status');
                $table->text('symptoms')->nullable();
                $table->text('notes')->nullable();
                $table->dateTime('scheduled_at')->nullable();
                $table->timestamps();
            });
        }

        $this->patient = User::factory()->create(['id' => Str::uuid()->toString()]);
        $this->doctor = User::factory()->create(['id' => Str::uuid()->toString()]);
        
        $this->appointment = Appointment::query()->create([
            'id' => Str::uuid()->toString(),
            'patient_user_id' => $this->patient->id,
            'doctor_user_id' => $this->doctor->id,
            'status' => 'CONFIRMED'
        ]);
    }

    public function test_user_can_join_webrtc_consultation()
    {
        Event::fake();

        $response = $this->actingAs($this->patient, 'api')
            ->postJson("/api/consultations/{$this->appointment->id}/webrtc/join", [], ['X-Tenant-Identifier' => 'tenant1']);

        $response->assertStatus(200);

        Event::assertDispatched(ConsultationJoined::class, function ($event) {
            return $event->consultationId === $this->appointment->id
                && $event->userId == $this->patient->id;
        });
    }

    public function test_user_can_send_webrtc_offer()
    {
        Event::fake();

        $sdp = ['type' => 'offer', 'sdp' => 'dummy sdp content'];

        $response = $this->actingAs($this->doctor, 'api')
            ->postJson("/api/consultations/{$this->appointment->id}/webrtc/offer", [
                'sdp' => $sdp['sdp'],
                'sdp_type' => $sdp['type']
            ], ['X-Tenant-Identifier' => 'tenant1']);

        $response->assertStatus(200);

        Event::assertDispatched(WebRtcOfferSent::class, function ($event) use ($sdp) {
            return $event->consultationId === $this->appointment->id
                && $event->userId == $this->doctor->id
                && $event->sdp === $sdp['sdp']
                && $event->sdpType === $sdp['type'];
        });
    }

    public function test_unauthorized_user_cannot_send_offer()
    {
        Event::fake();

        $unauthorizedUser = User::factory()->make(['id' => Str::uuid()->toString()]);
        $sdp = ['type' => 'offer', 'sdp' => 'dummy sdp'];

        $response = $this->actingAs($unauthorizedUser, 'api')
            ->postJson("/api/consultations/{$this->appointment->id}/webrtc/offer", [
                'sdp' => $sdp['sdp'],
                'sdp_type' => $sdp['type']
            ], ['X-Tenant-Identifier' => 'tenant1']);

        $response->assertStatus(403);
        Event::assertNotDispatched(WebRtcOfferSent::class);
    }
}
