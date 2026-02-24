<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class ChatMessagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_patient_can_send_and_doctor_can_ack_message(): void
    {
        Notification::fake();

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

        $appointment = Appointment::query()->create([
            'patient_user_id' => $patient->id,
            'doctor_user_id' => $doctor->id,
            'starts_at_utc' => '2026-02-20T10:00:00Z',
            'ends_at_utc' => '2026-02-20T10:30:00Z',
            'status' => 'CONFIRMED',
        ]);

        $send = $this->actingAs($patient, 'api')->postJson("/api/consultations/{$appointment->id}/messages", [
            'ciphertext' => 'ciphertext',
            'nonce' => 'nonce',
            'algorithm' => 'xchacha20poly1305',
            'key_id' => 'key-1',
        ]);

        $send->assertCreated();
        $messageId = $send->json('message.id');

        $ackDelivered = $this->actingAs($doctor, 'api')
            ->postJson("/api/consultations/{$appointment->id}/messages/{$messageId}/ack", [
                'status' => 'DELIVERED',
            ]);

        $ackDelivered->assertOk();
        $ackDelivered->assertJsonPath('status', 'DELIVERED');

        $ackRead = $this->actingAs($doctor, 'api')
            ->postJson("/api/consultations/{$appointment->id}/messages/{$messageId}/ack", [
                'status' => 'READ',
            ]);

        $ackRead->assertOk();
        $ackRead->assertJsonPath('status', 'READ');

        $this->assertDatabaseHas('chat_messages', [
            'id' => $messageId,
            'consultation_id' => $appointment->id,
            'sender_user_id' => $patient->id,
            'recipient_user_id' => $doctor->id,
        ]);

        $this->assertDatabaseHas('chat_message_statuses', [
            'message_id' => $messageId,
            'user_id' => $doctor->id,
            'status' => 'READ',
        ]);
    }
}
