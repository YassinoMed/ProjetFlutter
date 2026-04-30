<?php

namespace App\Services\WebRtc;

use App\Models\User;

class IceServerService
{
    /**
     * @return array{ice_servers: array<int, array<string, mixed>>, expires_at_utc: string|null, credential_mode: string}
     */
    public function forUser(User $user): array
    {
        $iceServers = [];

        foreach ($this->csvUrls((string) config('webrtc.stun_urls')) as $url) {
            $iceServers[] = ['urls' => $url];
        }

        $turnUrls = $this->csvUrls((string) config('webrtc.turn_urls'));
        $staticUsername = trim((string) config('webrtc.static_username'));
        $staticPassword = trim((string) config('webrtc.static_password'));
        $sharedSecret = trim((string) config('webrtc.shared_secret'));
        $ttlSeconds = max(300, min((int) config('webrtc.credential_ttl_seconds', 3600), 86400));

        if ($turnUrls === []) {
            return [
                'ice_servers' => $iceServers,
                'expires_at_utc' => null,
                'credential_mode' => 'stun_only',
            ];
        }

        if ($sharedSecret !== '') {
            $expiresAt = now('UTC')->addSeconds($ttlSeconds);
            $username = $expiresAt->timestamp.':'.$user->id;
            $credential = base64_encode(hash_hmac('sha1', $username, $sharedSecret, true));

            $iceServers[] = [
                'urls' => $turnUrls,
                'username' => $username,
                'credential' => $credential,
                'credentialType' => 'password',
            ];

            return [
                'ice_servers' => $iceServers,
                'expires_at_utc' => $expiresAt->toISOString(),
                'credential_mode' => 'ephemeral_hmac',
            ];
        }

        if ($staticUsername !== '' && $staticPassword !== '') {
            $iceServers[] = [
                'urls' => $turnUrls,
                'username' => $staticUsername,
                'credential' => $staticPassword,
                'credentialType' => 'password',
            ];

            return [
                'ice_servers' => $iceServers,
                'expires_at_utc' => null,
                'credential_mode' => 'static',
            ];
        }

        return [
            'ice_servers' => $iceServers,
            'expires_at_utc' => null,
            'credential_mode' => 'stun_only_missing_turn_credentials',
        ];
    }

    /**
     * @return array<int, string>
     */
    private function csvUrls(string $value): array
    {
        return collect(explode(',', $value))
            ->map(fn (string $url) => trim($url))
            ->filter(fn (string $url) => $url !== '')
            ->values()
            ->all();
    }
}
