<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Rgpd\ConsentRequest;
use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Models\FcmToken;
use App\Models\UserConsent;
use App\Services\UserAnonymizationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class RgpdController extends Controller
{
    public function __construct(
        private readonly UserAnonymizationService $anonymization,
    ) {}

    public function export(): JsonResponse
    {
        $user = request()->user();

        $appointments = Appointment::query()
            ->where('patient_user_id', $user->id)
            ->orWhere('doctor_user_id', $user->id)
            ->orderBy('starts_at_utc')
            ->get();

        $consultationIds = $appointments->pluck('id')->all();

        $messages = ChatMessage::query()
            ->whereIn('consultation_id', $consultationIds)
            ->where(function ($q) use ($user) {
                $q->where('sender_user_id', $user->id)->orWhere('recipient_user_id', $user->id);
            })
            ->orderBy('sent_at_utc')
            ->get();

        $consents = UserConsent::query()->where('user_id', $user->id)->get();

        $tokens = FcmToken::query()->where('user_id', $user->id)->get();

        $this->logAudit('rgpd_export', [
            'user_id'      => $user->id,
            'appointments' => $appointments->count(),
            'messages'     => $messages->count(),
        ]);

        return $this->respondSuccess([
            'user' => [
                'id'             => $user->id,
                'email'          => $user->email,
                'first_name'     => $user->first_name,
                'last_name'      => $user->last_name,
                'phone'          => $user->phone,
                'role'           => $user->role?->value ?? $user->role,
                'created_at_utc' => optional($user->created_at)?->setTimezone('UTC')?->toISOString(),
            ],
            'appointments'   => $appointments,
            'chat_messages'  => $messages,
            'fcm_tokens'     => $tokens,
            'consents'       => $consents,
            'exported_at_utc' => now('UTC')->toISOString(),
        ], 'RGPD Export successful');
    }

    public function consent(ConsentRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();

        $consentedAt = $data['consented'] ? now('UTC') : null;
        $revokedAt = $data['consented'] ? null : now('UTC');

        $consent = UserConsent::query()->updateOrCreate(
            [
                'user_id'      => $user->id,
                'consent_type' => $data['consent_type'],
            ],
            [
                'consented'        => $data['consented'],
                'consented_at_utc' => $consentedAt,
                'revoked_at_utc'   => $revokedAt,
            ],
        );

        $this->logAudit('rgpd_consent', [
            'user_id'      => $user->id,
            'consent_type' => $data['consent_type'],
            'consented'    => $data['consented'],
        ]);

        return $this->respondSuccess([
            'consent' => $consent,
        ], 'Consent processed successfully');
    }

    /**
     * RGPD Art. 17 – Right to be forgotten (user-initiated).
     *
     * Refactored: now delegates to shared UserAnonymizationService
     * instead of containing its own duplicated anonymization logic.
     */
    public function forget(): JsonResponse
    {
        $user = request()->user();

        $this->anonymization->anonymize(
            user: $user,
            actorId: $user->id,
            reason: 'user_self_service_forget',
            revokeTokens: true,
            deleteFcmTokens: true,
        );

        return $this->respondSuccess(null, 'User forgotten successfully');
    }

    private function logAudit(string $event, array $properties): void
    {
        if (function_exists('activity')) {
            activity('security')
                ->causedBy(request()->user())
                ->withProperties($properties)
                ->event($event)
                ->log($event);

            return;
        }

        Log::channel('security')->info($event, $properties);
    }
}
