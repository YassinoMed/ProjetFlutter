<?php

namespace App\Services\Auth;

use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\UnauthorizedHttpException;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthTokenService
{
    public function issueForUser(User $user, Request $request): array
    {
        return DB::transaction(function () use ($user, $request): array {
            $access = $this->makeToken($user, 'access', (int) config('jwt.ttl'));
            $refresh = $this->makeToken($user, 'refresh', (int) config('jwt.refresh_ttl'));

            RefreshToken::query()->create([
                'user_id' => $user->id,
                'jti_hash' => hash('sha256', $refresh['jti']),
                'expires_at_utc' => $refresh['expires_at_utc'],
                'issued_ip' => $request->ip(),
                'issued_user_agent' => $request->userAgent(),
            ]);

            return [
                'access_token' => $access['token'],
                'access_expires_at_utc' => $access['expires_at_utc']->toISOString(),
                'refresh_token' => $refresh['token'],
                'refresh_expires_at_utc' => $refresh['expires_at_utc']->toISOString(),
                'token_type' => 'Bearer',
            ];
        });
    }

    public function rotateRefresh(string $refreshToken, Request $request): array
    {
        return DB::transaction(function () use ($refreshToken, $request): array {
            $payload = $this->payloadFromToken($refreshToken);

            if (($payload['typ'] ?? null) !== 'refresh') {
                throw new UnauthorizedHttpException('Bearer', 'Invalid refresh token type');
            }

            $userId = (string) ($payload['sub'] ?? '');
            $jti = (string) ($payload['jti'] ?? '');

            if ($userId === '' || $jti === '') {
                throw new UnauthorizedHttpException('Bearer', 'Invalid refresh token');
            }

            $jtiHash = hash('sha256', $jti);

            $stored = RefreshToken::query()
                ->where('jti_hash', $jtiHash)
                ->lockForUpdate()
                ->first();

            if ($stored === null) {
                throw new UnauthorizedHttpException('Bearer', 'Refresh token revoked');
            }

            if ($stored->revoked_at_utc !== null) {
                throw new UnauthorizedHttpException('Bearer', 'Refresh token revoked');
            }

            if ($stored->expires_at_utc->lte(now('UTC'))) {
                throw new UnauthorizedHttpException('Bearer', 'Refresh token expired');
            }

            $user = User::query()->findOrFail($userId);

            $access = $this->makeToken($user, 'access', (int) config('jwt.ttl'));
            $newRefresh = $this->makeToken($user, 'refresh', (int) config('jwt.refresh_ttl'));

            $newHash = hash('sha256', $newRefresh['jti']);

            $stored->update([
                'revoked_at_utc' => now('UTC'),
                'replaced_by_jti_hash' => $newHash,
            ]);

            RefreshToken::query()->create([
                'user_id' => $user->id,
                'jti_hash' => $newHash,
                'expires_at_utc' => $newRefresh['expires_at_utc'],
                'issued_ip' => $request->ip(),
                'issued_user_agent' => $request->userAgent(),
            ]);

            return [
                'access_token' => $access['token'],
                'access_expires_at_utc' => $access['expires_at_utc']->toISOString(),
                'refresh_token' => $newRefresh['token'],
                'refresh_expires_at_utc' => $newRefresh['expires_at_utc']->toISOString(),
                'token_type' => 'Bearer',
            ];
        });
    }

    public function logout(Request $request): void
    {
        try {
            JWTAuth::invalidate(true);
        } catch (\Throwable) {
        }

        $user = $request->user();

        if ($user !== null) {
            RefreshToken::query()
                ->where('user_id', $user->id)
                ->whereNull('revoked_at_utc')
                ->update(['revoked_at_utc' => now('UTC')]);
        }
    }

    private function makeToken(User $user, string $typ, int $ttlMinutes): array
    {
        $factory = JWTAuth::factory();
        $originalTtl = method_exists($factory, 'getTTL') ? $factory->getTTL() : null;

        $factory->setTTL($ttlMinutes);

        $jti = (string) Str::uuid();
        $token = JWTAuth::claims([
            'typ' => $typ,
            'jti' => $jti,
        ])->fromUser($user);

        if ($originalTtl !== null) {
            $factory->setTTL($originalTtl);
        }

        $expiresAtUtc = now('UTC')->addMinutes($ttlMinutes);

        return [
            'token' => $token,
            'jti' => $jti,
            'expires_at_utc' => $expiresAtUtc,
        ];
    }

    private function payloadFromToken(string $token): array
    {
        try {
            return JWTAuth::setToken($token)->getPayload()->toArray();
        } catch (\Throwable) {
            throw new UnauthorizedHttpException('Bearer', 'Invalid token');
        }
    }
}
