<?php

namespace Tests\Feature;

use App\Events\ConversationMessageCreated;
use App\Events\ConversationMessageReceiptUpdated;
use App\Models\Appointment;
use App\Models\User;
use App\Notifications\SecureMessageNotification;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class SecureMessagingEndpointsTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        $this->bootTenantSchema();
    }

    public function test_patient_and_doctor_can_exchange_e2ee_transport_messages(): void
    {
        Event::fake([
            ConversationMessageCreated::class,
            ConversationMessageReceiptUpdated::class,
        ]);
        Notification::fake();

        $patient = User::factory()->create([
            'role' => 'PATIENT',
            'first_name' => 'Patient',
            'last_name' => 'One',
        ]);
        $doctor = User::factory()->create([
            'role' => 'DOCTOR',
            'first_name' => 'Doctor',
            'last_name' => 'One',
        ]);

        $consultation = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-10 09:00:00',
            'ends_at_utc' => '2026-03-10 09:30:00',
            'status' => 'CONFIRMED',
        ]);

        Sanctum::actingAs($patient);

        $conversationResponse = $this->postJson('/api/conversations', [
            'participant_user_id' => $doctor->id,
            'consultation_id' => $consultation->id,
        ]);

        $conversationResponse->assertCreated();
        $conversationId = $conversationResponse->json('data.id');

        $messageResponse = $this->postJson('/api/messages', [
            'conversation_id' => $conversationId,
            'client_message_id' => 'client-msg-1',
            'message_type' => 'TEXT',
            'ciphertext' => 'base64:ciphertext',
            'nonce' => 'base64:nonce',
            'e2ee_version' => '1',
            'sender_key_id' => 'device-key-1',
            'server_metadata' => [
                'has_attachment' => false,
            ],
        ]);

        $messageResponse->assertCreated();
        $messageId = $messageResponse->json('data.message.id');

        Notification::assertSentTo($doctor, SecureMessageNotification::class);

        Sanctum::actingAs($doctor);

        $deliveredResponse = $this->postJson("/api/messages/{$messageId}/delivered", [
            'status' => 'DELIVERED',
        ]);

        $deliveredResponse->assertOk();
        $deliveredResponse->assertJsonPath('data.status', 'DELIVERED');

        $readResponse = $this->postJson("/api/messages/{$messageId}/read", [
            'status' => 'READ',
        ]);

        $readResponse->assertOk();
        $readResponse->assertJsonPath('data.status', 'READ');

        $historyResponse = $this->getJson("/api/conversations/{$conversationId}/messages");

        $historyResponse->assertOk();
        $historyResponse->assertJsonPath('data.0.id', $messageId);
        $historyResponse->assertJsonPath('data.0.ciphertext', 'base64:ciphertext');

        $this->assertDatabaseHas('messages', [
            'id' => $messageId,
            'conversation_id' => $conversationId,
            'sender_user_id' => $patient->id,
            'ciphertext' => 'base64:ciphertext',
        ]);

        $this->assertDatabaseHas('message_receipts', [
            'message_id' => $messageId,
            'user_id' => $doctor->id,
            'status' => 'READ',
        ]);
    }

    public function test_unrelated_user_cannot_read_conversation_or_fetch_bundle(): void
    {
        $patient = User::factory()->create(['role' => 'PATIENT']);
        $doctor = User::factory()->create(['role' => 'DOCTOR']);
        $intruder = User::factory()->create(['role' => 'DOCTOR']);

        $consultation = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-03-10 09:00:00',
            'ends_at_utc' => '2026-03-10 09:30:00',
            'status' => 'CONFIRMED',
        ]);

        Sanctum::actingAs($patient);

        $conversationId = $this->postJson('/api/conversations', [
            'participant_user_id' => $doctor->id,
            'consultation_id' => $consultation->id,
        ])->json('data.id');

        $this->postJson('/api/e2ee/devices', [
            'device_id' => 'patient-device-1',
            'bundle_version' => '1',
            'identity_key_algorithm' => 'X25519',
            'identity_key_public' => 'pub-identity',
            'signed_pre_key_id' => 'signed-1',
            'signed_pre_key_public' => 'pub-signed',
            'signed_pre_key_signature' => 'sig',
            'one_time_pre_keys' => [
                ['key_id' => 'otp-1', 'public_key' => 'pub-otp-1'],
            ],
        ])->assertOk();

        Sanctum::actingAs($intruder);

        $this->getJson("/api/conversations/{$conversationId}")
            ->assertForbidden();

        $this->getJson("/api/e2ee/users/{$patient->id}/bundle?consultation_id={$consultation->id}")
            ->assertForbidden();
    }
}
