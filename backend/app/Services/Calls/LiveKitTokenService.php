<?php

namespace App\Services\Calls;

use App\Models\CallSession;
use App\Models\User;
use Illuminate\Support\Carbon;
use JsonException;
use RuntimeException;

class LiveKitTokenService
{
    /**
     * @throws JsonException
     */
    public function issueForCall(CallSession $callSession, User $user): array
    {
        $apiKey = (string) config('services.livekit.api_key', '');
        $apiSecret = (string) config('services.livekit.api_secret', '');
        $url = (string) config('services.livekit.url', '');

        if ($apiKey === '' || $apiSecret === '' || $url === '') {
            throw new RuntimeException('LiveKit is not configured.');
        }

        $now = Carbon::now('UTC');
        $expiresAt = $now->copy()->addSeconds(
            max(60, (int) config('services.livekit.token_ttl_seconds', 3600)),
        );
        $roomName = $this->roomName($callSession);

        $payload = [
            'iss' => $apiKey,
            'sub' => (string) $user->id,
            'name' => $this->displayName($user),
            'nbf' => $now->copy()->subSeconds(10)->timestamp,
            'exp' => $expiresAt->timestamp,
            'video' => [
                'room' => $roomName,
                'roomJoin' => true,
                'canPublish' => true,
                'canSubscribe' => true,
                'canPublishData' => true,
            ],
            'metadata' => json_encode([
                'user_id' => (string) $user->id,
                'call_session_id' => (string) $callSession->id,
                'conversation_id' => (string) $callSession->conversation_id,
                'consultation_id' => $callSession->consultation_id,
                'role' => $callSession->initiated_by_user_id === $user->id ? 'caller' : 'callee',
            ], JSON_THROW_ON_ERROR),
        ];

        return [
            'url' => $url,
            'token' => $this->signJwt($payload, $apiSecret),
            'room' => $roomName,
            'expires_at_utc' => $expiresAt->toISOString(),
        ];
    }

    public function roomName(CallSession $callSession): string
    {
        $metadata = $callSession->server_metadata ?? [];

        if (! empty($metadata['livekit_room'])) {
            return (string) $metadata['livekit_room'];
        }

        return 'call-'.$callSession->id;
    }

    private function displayName(User $user): string
    {
        $name = trim(sprintf('%s %s', $user->first_name ?? '', $user->last_name ?? ''));

        return $name !== '' ? $name : ((string) ($user->email ?? $user->id));
    }

    /**
     * @throws JsonException
     */
    private function signJwt(array $payload, string $secret): string
    {
        $header = $this->base64UrlEncode(json_encode([
            'alg' => 'HS256',
            'typ' => 'JWT',
        ], JSON_THROW_ON_ERROR));
        $body = $this->base64UrlEncode(json_encode($payload, JSON_THROW_ON_ERROR));
        $signature = hash_hmac('sha256', $header.'.'.$body, $secret, true);

        return $header.'.'.$body.'.'.$this->base64UrlEncode($signature);
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
