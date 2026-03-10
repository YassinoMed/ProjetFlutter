<?php

namespace App\Services\Auth;

use App\Models\User;
use Illuminate\Http\Request;

/**
 * AuthTokenService — Sanctum personal access tokens.
 *
 * Replaces the previous JWT-based implementation.
 * Sanctum tokens are opaque strings stored as SHA-256 hashes in `personal_access_tokens`.
 * No refresh tokens, no rotation — a single token per device session.
 */
class AuthTokenService
{
    /**
     * Issue a Sanctum personal access token for the user.
     *
     * The token name is the device_name (or a fallback), making it easy to
     * identify which token belongs to which device in the DB.
     */
    public function issueForUser(User $user, Request $request): array
    {
        $deviceName = $request->input('device_name', $request->userAgent() ?? 'Unknown Device');

        $token = $user->createToken(
            name: $deviceName,
            abilities: ['*'],
        );

        return [
            'token'      => $token->plainTextToken,
            'token_type' => 'Bearer',
        ];
    }

    /**
     * Revoke the current session token (logout).
     */
    public function logout(Request $request): void
    {
        $user = $request->user();

        if ($user !== null) {
            // Delete only the current token (not all tokens)
            $user->currentAccessToken()?->delete();
        }
    }

    /**
     * Revoke ALL tokens for a user (e.g. password changed, account compromised).
     */
    public function revokeAllTokens(User $user): void
    {
        $user->tokens()->delete();
    }

    /**
     * Revoke tokens by device name.
     * Used when revoking a TrustedDevice — we delete all tokens whose
     * `name` matches the device_name stored in the TrustedDevice record.
     */
    public function revokeTokensByDeviceName(User $user, string $deviceName): void
    {
        $user->tokens()->where('name', $deviceName)->delete();
    }
}
