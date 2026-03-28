<?php

namespace App\Services\Teleconsultations;

use App\Models\User;
use Illuminate\Support\Carbon;

class TurnCredentialsService
{
    public function forUser(User $user): array
    {
        $stunUrls = config('mediconnect.turn.stun_urls', []);
        $turnUrls = config('mediconnect.turn.turn_urls', []);

        $iceServers = [];

        if (! empty($stunUrls)) {
            $iceServers[] = ['urls' => array_values($stunUrls)];
        }

        [$username, $credential, $expiresAtUtc] = $this->resolveTurnCredentials($user);

        if (! empty($turnUrls) && $username !== null && $credential !== null) {
            $iceServers[] = [
                'urls' => array_values($turnUrls),
                'username' => $username,
                'credential' => $credential,
            ];
        }

        return [
            'ice_servers' => $iceServers,
            'ice_transport_policy' => 'all',
            'bundle_policy' => 'balanced',
            'rtcp_mux_policy' => 'require',
            'credentials_expires_at_utc' => $expiresAtUtc?->setTimezone('UTC')->toISOString(),
        ];
    }

    /**
     * @return array{0:?string,1:?string,2:?Carbon}
     */
    private function resolveTurnCredentials(User $user): array
    {
        $ttl = max((int) config('mediconnect.turn.credential_ttl_seconds', 3600), 300);
        $expiresAtUtc = now('UTC')->addSeconds($ttl);

        $sharedSecret = config('mediconnect.turn.shared_secret');
        if (is_string($sharedSecret) && $sharedSecret !== '') {
            $username = $expiresAtUtc->timestamp.':'.$user->id;
            $credential = base64_encode(hash_hmac('sha1', $username, $sharedSecret, true));

            return [$username, $credential, $expiresAtUtc];
        }

        $username = config('mediconnect.turn.username');
        $password = config('mediconnect.turn.password');

        if (is_string($username) && $username !== '' && is_string($password) && $password !== '') {
            return [$username, $password, $expiresAtUtc];
        }

        return [null, null, null];
    }
}
