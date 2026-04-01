<?php

namespace App\Services\Teleconsultations;

use App\Models\CallEvent;
use App\Models\CallSession;
use App\Models\Teleconsultation;
use App\Models\User;

class TeleconsultationEventLogger
{
    public function __construct(
        private readonly TeleconsultationSchemaGuard $schemaGuard,
    ) {}

    public function record(
        Teleconsultation $teleconsultation,
        string $eventName,
        ?User $actor = null,
        ?string $targetUserId = null,
        ?CallSession $callSession = null,
        array $payload = [],
        ?string $direction = null,
    ): void {
        if (! $this->schemaGuard->isAvailable()) {
            return;
        }

        CallEvent::query()->create([
            'teleconsultation_id' => $teleconsultation->id,
            'call_session_id' => $callSession?->id ?? $teleconsultation->current_call_session_id,
            'actor_user_id' => $actor?->id,
            'target_user_id' => $targetUserId,
            'event_name' => $eventName,
            'direction' => $direction,
            'payload' => $this->sanitizePayload($payload),
            'occurred_at_utc' => now('UTC'),
        ]);
    }

    public function recordForCallSession(
        CallSession $callSession,
        string $eventName,
        ?User $actor = null,
        ?string $targetUserId = null,
        array $payload = [],
        ?string $direction = null,
    ): void {
        $teleconsultation = $this->resolveForCallSession($callSession);

        if ($teleconsultation === null) {
            return;
        }

        $this->record(
            $teleconsultation,
            $eventName,
            $actor,
            $targetUserId,
            $callSession,
            $payload,
            $direction,
        );
    }

    public function resolveForCallSession(CallSession $callSession): ?Teleconsultation
    {
        if (! $this->schemaGuard->isAvailable()) {
            return null;
        }

        return Teleconsultation::query()
            ->where('current_call_session_id', $callSession->id)
            ->orWhere(fn ($query) => $query->where('appointment_id', $callSession->consultation_id))
            ->orderByDesc('updated_at')
            ->first();
    }

    private function sanitizePayload(array $payload): array
    {
        $sanitized = $payload;

        if (isset($sanitized['sdp']) && is_array($sanitized['sdp'])) {
            $sanitized['sdp'] = [
                'type' => $sanitized['sdp']['type'] ?? null,
                'length' => strlen((string) ($sanitized['sdp']['sdp'] ?? '')),
            ];
        }

        if (isset($sanitized['candidate']) && is_array($sanitized['candidate'])) {
            $sanitized['candidate'] = [
                'sdpMid' => $sanitized['candidate']['sdpMid'] ?? null,
                'sdpMLineIndex' => $sanitized['candidate']['sdpMLineIndex'] ?? null,
                'usernameFragment' => $sanitized['candidate']['usernameFragment'] ?? null,
                'length' => strlen((string) ($sanitized['candidate']['candidate'] ?? '')),
            ];
        }

        return $sanitized;
    }
}
