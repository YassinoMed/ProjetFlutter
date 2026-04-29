<?php

namespace Tests\Feature;

use App\Events\CallSessionAccepted;
use App\Events\CallSessionEnded;
use App\Events\CallSessionRinging;
use App\Events\WebRtcAnswerRelayed;
use App\Events\WebRtcIceCandidateRelayed;
use App\Events\WebRtcOfferRelayed;
use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Models\User;
use App\Notifications\IncomingCallSessionNotification;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class CallSessionEndpointsTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
    }

    public function test_doctor_and_patient_can_complete_call_signaling_flow(): void
    {
        Event::fake([
            CallSessionRinging::class,
            CallSessionAccepted::class,
            CallSessionEnded::class,
            WebRtcOfferRelayed::class,
            WebRtcAnswerRelayed::class,
            WebRtcIceCandidateRelayed::class,
        ]);
        Notification::fake();

        $patient = User::factory()->create(['role' => 'PATIENT']);
        $doctor = User::factory()->create(['role' => 'DOCTOR']);

        $consultation = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-10 10:00:00',
            'ends_at_utc' => '2026-03-10 10:30:00',
            'status' => 'CONFIRMED',
        ]);

        $conversation = Conversation::query()->create([
            'consultation_id' => $consultation->id,
            'initiated_by_user_id' => $doctor->id,
            'type' => 'DIRECT_MEDICAL',
        ]);

        $conversation->participants()->createMany([
            [
                'user_id' => $doctor->id,
                'role' => 'DOCTOR',
                'is_active' => true,
                'joined_at_utc' => now('UTC'),
            ],
            [
                'user_id' => $patient->id,
                'role' => 'PATIENT',
                'is_active' => true,
                'joined_at_utc' => now('UTC'),
            ],
        ]);

        Sanctum::actingAs($doctor);

        $initiateResponse = $this->postJson('/api/calls/initiate', [
            'conversation_id' => $conversation->id,
            'consultation_id' => $consultation->id,
            'call_type' => 'VIDEO',
        ]);

        $initiateResponse->assertCreated();
        $callSessionId = $initiateResponse->json('data.call_session.id');
        $initiateResponse->assertJsonPath('data.call_session.current_state', 'RINGING');

        Notification::assertSentTo($patient, IncomingCallSessionNotification::class);
        Event::assertDispatched(CallSessionRinging::class);

        Sanctum::actingAs($patient);

        $this->postJson("/api/calls/{$callSessionId}/accept")
            ->assertOk()
            ->assertJsonPath('data.call_session.current_state', 'ACCEPTED');

        Event::assertDispatched(CallSessionAccepted::class);

        Sanctum::actingAs($doctor);

        $this->postJson("/api/calls/{$callSessionId}/offer", [
            'target_user_id' => $patient->id,
            'sdp' => [
                'type' => 'offer',
                'sdp' => 'offer-sdp',
            ],
        ])->assertOk();

        Event::assertDispatched(WebRtcOfferRelayed::class);

        Sanctum::actingAs($patient);

        $this->postJson("/api/calls/{$callSessionId}/answer", [
            'target_user_id' => $doctor->id,
            'sdp' => [
                'type' => 'answer',
                'sdp' => 'answer-sdp',
            ],
        ])->assertOk();

        $this->postJson("/api/calls/{$callSessionId}/ice-candidates", [
            'target_user_id' => $doctor->id,
            'candidate' => [
                'candidate' => 'candidate:1 1 UDP 2122260223 192.0.2.3 54400 typ host',
                'sdpMid' => '0',
                'sdpMLineIndex' => 0,
            ],
        ])->assertOk();

        Event::assertDispatched(WebRtcAnswerRelayed::class);
        Event::assertDispatched(WebRtcIceCandidateRelayed::class);

        Sanctum::actingAs($doctor);

        $this->postJson("/api/calls/{$callSessionId}/end")
            ->assertOk()
            ->assertJsonPath('data.call_session.current_state', 'ENDED');

        Event::assertDispatched(CallSessionEnded::class);

        $this->assertDatabaseHas('call_sessions', [
            'id' => $callSessionId,
            'current_state' => 'ENDED',
        ]);
    }

    public function test_unrelated_user_cannot_signal_call(): void
    {
        Event::fake([
            CallSessionRinging::class,
        ]);
        Notification::fake();

        $patient = User::factory()->create(['role' => 'PATIENT']);
        $doctor = User::factory()->create(['role' => 'DOCTOR']);
        $intruder = User::factory()->create(['role' => 'PATIENT']);

        $consultation = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-10 10:00:00',
            'ends_at_utc' => '2026-03-10 10:30:00',
            'status' => 'CONFIRMED',
        ]);

        $conversation = Conversation::query()->create([
            'consultation_id' => $consultation->id,
            'initiated_by_user_id' => $doctor->id,
            'type' => 'DIRECT_MEDICAL',
        ]);

        $conversation->participants()->createMany([
            ['user_id' => $doctor->id, 'role' => 'DOCTOR', 'is_active' => true, 'joined_at_utc' => now('UTC')],
            ['user_id' => $patient->id, 'role' => 'PATIENT', 'is_active' => true, 'joined_at_utc' => now('UTC')],
        ]);

        Sanctum::actingAs($doctor);
        $callSessionId = $this->postJson('/api/calls/initiate', [
            'conversation_id' => $conversation->id,
            'consultation_id' => $consultation->id,
            'call_type' => 'VIDEO',
        ])->json('data.call_session.id');

        Sanctum::actingAs($intruder);

        $this->postJson("/api/calls/{$callSessionId}/offer", [
            'target_user_id' => $patient->id,
            'sdp' => [
                'type' => 'offer',
                'sdp' => 'offer-sdp',
            ],
        ])->assertForbidden();
    }

    public function test_expired_call_session_cannot_be_accepted(): void
    {
        Notification::fake();
        Queue::fake();

        [$doctor, $patient, $callSessionId] = $this->createRingingCallSession();

        CallSession::query()
            ->whereKey($callSessionId)
            ->update(['expires_at_utc' => now('UTC')->subMinute()]);

        Sanctum::actingAs($patient);

        $this->postJson("/api/calls/{$callSessionId}/accept")
            ->assertStatus(409);

        $this->assertDatabaseHas('call_sessions', [
            'id' => $callSessionId,
            'current_state' => 'TIMEOUT',
        ]);

        Sanctum::actingAs($doctor);

        $this->postJson("/api/calls/{$callSessionId}/end")
            ->assertStatus(409);
    }

    public function test_ended_call_session_cannot_be_ended_again(): void
    {
        Notification::fake();
        Queue::fake();

        [$doctor, $patient, $callSessionId] = $this->createRingingCallSession();

        Sanctum::actingAs($patient);
        $this->postJson("/api/calls/{$callSessionId}/accept")->assertOk();

        Sanctum::actingAs($doctor);
        $this->postJson("/api/calls/{$callSessionId}/end")->assertOk();

        $this->postJson("/api/calls/{$callSessionId}/end")
            ->assertStatus(409);
    }

    public function test_callee_cannot_cancel_ringing_call_directly(): void
    {
        Notification::fake();
        Queue::fake();

        [, $patient, $callSessionId] = $this->createRingingCallSession();

        Sanctum::actingAs($patient);

        $this->postJson("/api/calls/{$callSessionId}/cancel")
            ->assertForbidden();
    }

    private function createRingingCallSession(): array
    {
        $patient = User::factory()->create(['role' => 'PATIENT']);
        $doctor = User::factory()->create(['role' => 'DOCTOR']);

        $consultation = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-10 10:00:00',
            'ends_at_utc' => '2026-03-10 10:30:00',
            'status' => 'CONFIRMED',
        ]);

        $conversation = Conversation::query()->create([
            'consultation_id' => $consultation->id,
            'initiated_by_user_id' => $doctor->id,
            'type' => 'DIRECT_MEDICAL',
        ]);

        $conversation->participants()->createMany([
            ['user_id' => $doctor->id, 'role' => 'DOCTOR', 'is_active' => true, 'joined_at_utc' => now('UTC')],
            ['user_id' => $patient->id, 'role' => 'PATIENT', 'is_active' => true, 'joined_at_utc' => now('UTC')],
        ]);

        Sanctum::actingAs($doctor);

        $callSessionId = $this->postJson('/api/calls/initiate', [
            'conversation_id' => $conversation->id,
            'consultation_id' => $consultation->id,
            'call_type' => 'VIDEO',
        ])
            ->assertCreated()
            ->json('data.call_session.id');

        return [$doctor, $patient, $callSessionId];
    }
}
