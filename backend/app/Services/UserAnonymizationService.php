<?php

namespace App\Services;

use App\Models\FcmToken;
use App\Models\RefreshToken;
use App\Models\User;
use App\Models\UserConsent;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Service unifié d'anonymisation RGPD (Art. 17 – Droit à l'oubli).
 *
 * Centralise la logique d'anonymisation utilisée par :
 * - Admin\RgpdController::anonymize()  (action admin)
 * - Api\RgpdController::forget()       (droit utilisateur)
 *
 * Élimine la duplication et garantit un comportement identique.
 */
class UserAnonymizationService
{
    /**
     * Anonymize a user and purge their associated personal data.
     *
     * @param User        $user             The user to anonymize
     * @param string|null $actorId          The admin or user who triggered the action
     * @param string|null $reason           Legal/admin reason for anonymization
     * @param bool        $revokeTokens     Also revoke refresh tokens (API-initiated)
     * @param bool        $deleteFcmTokens  Also delete FCM push tokens
     */
    public function anonymize(
        User $user,
        ?string $actorId = null,
        ?string $reason = null,
        bool $revokeTokens = true,
        bool $deleteFcmTokens = true,
    ): void {
        DB::transaction(function () use ($user, $revokeTokens, $deleteFcmTokens) {
            // Anonymize personal data
            $user->update([
                'email'      => "anonymized+{$user->id}@mediconnect.local",
                'first_name' => 'Anonyme',
                'last_name'  => 'Utilisateur',
                'phone'      => null,
                'password'   => Str::random(64), // Invalidate auth
            ]);

            // Purge consents
            UserConsent::where('user_id', $user->id)->delete();

            // Revoke API tokens if requested
            if ($revokeTokens) {
                RefreshToken::where('user_id', $user->id)
                    ->whereNull('revoked_at_utc')
                    ->update(['revoked_at_utc' => now('UTC')]);
            }

            // Remove push tokens if requested
            if ($deleteFcmTokens) {
                FcmToken::where('user_id', $user->id)->delete();
            }
        });

        // Audit trail
        Log::channel('security')->info('rgpd_user_anonymized', array_filter([
            'user_id'  => $user->id,
            'actor_id' => $actorId,
            'reason'   => $reason,
        ]));
    }
}
