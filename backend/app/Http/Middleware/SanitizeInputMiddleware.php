<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Input Sanitization Middleware.
 *
 * Strips potentially dangerous HTML/JS from all input strings
 * to protect against stored XSS attacks.
 *
 * Exceptions:
 * - Fields containing 'password' (should not be modified)
 * - Fields containing 'ciphertext' / 'nonce' (E2EE encrypted data)
 * - Fields containing 'token' (JWT/refresh tokens)
 * - Fields containing 'encrypted' (any encrypted payload)
 */
class SanitizeInputMiddleware
{
    /**
     * Fields that should NOT be sanitized (exact or partial match).
     */
    private array $except = [
        'password',
        'password_confirmation',
        'current_password',
        'ciphertext',
        'nonce',
        'token',
        'refresh_token',
        'metadata_encrypted',
        'encrypted',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $input = $request->all();
        $sanitized = $this->sanitizeArray($input);
        $request->merge($sanitized);

        return $next($request);
    }

    /**
     * Recursively sanitize an array of inputs.
     */
    private function sanitizeArray(array $data, string $parentKey = ''): array
    {
        foreach ($data as $key => $value) {
            $fullKey = $parentKey ? "{$parentKey}.{$key}" : (string) $key;

            if ($this->shouldSkip($key)) {
                continue;
            }

            if (is_array($value)) {
                $data[$key] = $this->sanitizeArray($value, $fullKey);
            } elseif (is_string($value)) {
                $data[$key] = $this->sanitizeString($value);
            }
        }

        return $data;
    }

    /**
     * Sanitize a single string value.
     */
    private function sanitizeString(string $value): string
    {
        // Strip HTML tags
        $value = strip_tags($value);

        // Remove null bytes
        $value = str_replace(chr(0), '', $value);

        return trim($value);
    }

    /**
     * Check if a field should be skipped from sanitization.
     */
    private function shouldSkip(string|int $key): bool
    {
        if (is_int($key)) {
            return false;
        }

        foreach ($this->except as $except) {
            if (str_contains(strtolower($key), strtolower($except))) {
                return true;
            }
        }

        return false;
    }
}
