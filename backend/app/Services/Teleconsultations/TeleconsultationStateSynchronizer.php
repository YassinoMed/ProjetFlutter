<?php

namespace App\Services\Teleconsultations;

use App\Enums\CallSessionState;
use App\Enums\TeleconsultationStatus;
use App\Events\TeleconsultationUpdated;
use App\Models\CallSession;
use App\Models\Teleconsultation;
use Illuminate\Support\Facades\DB;

class TeleconsultationStateSynchronizer
{
    public function __construct(
        private readonly TeleconsultationSchemaGuard $schemaGuard,
    ) {}

    public function syncFromCallSession(CallSession $callSession): ?Teleconsultation
    {
        if (! $this->schemaGuard->isAvailable()) {
            return null;
        }

        $teleconsultation = Teleconsultation::query()
            ->where('current_call_session_id', $callSession->id)
            ->orWhere(fn ($query) => $query->where('appointment_id', $callSession->consultation_id))
            ->first();

        if ($teleconsultation === null) {
            return null;
        }

        $status = $callSession->current_state?->value ?? $callSession->current_state;

        $updates = [
            'current_call_session_id' => $callSession->id,
            'conversation_id' => $teleconsultation->conversation_id ?? $callSession->conversation_id,
            'expires_at_utc' => $callSession->expires_at_utc,
        ];

        switch ($status) {
            case CallSessionState::RINGING->value:
            case CallSessionState::INITIATED->value:
                $updates['status'] = TeleconsultationStatus::RINGING->value;
                $updates['ringing_started_at_utc'] = $callSession->started_ringing_at_utc ?? now('UTC');
                $updates['failure_reason'] = null;
                break;

            case CallSessionState::ACCEPTED->value:
                $updates['status'] = TeleconsultationStatus::ACTIVE->value;
                $updates['started_at_utc'] = $callSession->accepted_at_utc ?? now('UTC');
                $updates['expires_at_utc'] = null;
                $updates['failure_reason'] = null;
                break;

            case CallSessionState::REJECTED->value:
            case CallSessionState::MISSED->value:
                $updates['status'] = TeleconsultationStatus::MISSED->value;
                $updates['ended_at_utc'] = $callSession->ended_at_utc ?? now('UTC');
                $updates['failure_reason'] = $callSession->end_reason ?? 'rejected';
                break;

            case CallSessionState::CANCELLED->value:
                $updates['status'] = TeleconsultationStatus::CANCELLED->value;
                $updates['ended_at_utc'] = $callSession->ended_at_utc ?? now('UTC');
                $updates['cancellation_reason'] = $teleconsultation->cancellation_reason ?? $callSession->end_reason;
                break;

            case CallSessionState::ENDED->value:
                $updates['status'] = TeleconsultationStatus::COMPLETED->value;
                $updates['ended_at_utc'] = $callSession->ended_at_utc ?? now('UTC');
                $updates['expires_at_utc'] = null;
                break;

            case CallSessionState::TIMEOUT->value:
                $updates['status'] = TeleconsultationStatus::EXPIRED->value;
                $updates['ended_at_utc'] = $callSession->ended_at_utc ?? now('UTC');
                $updates['failure_reason'] = $callSession->end_reason ?? 'timeout';
                break;
        }

        $teleconsultation->forceFill($updates)->save();
        $teleconsultation = $teleconsultation->fresh(['participants', 'currentCallSession']);

        DB::afterCommit(fn () => event(new TeleconsultationUpdated($teleconsultation)));

        return $teleconsultation;
    }
}
