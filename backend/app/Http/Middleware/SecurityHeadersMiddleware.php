<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Comprehensive Security Headers Middleware.
 *
 * Implements OWASP recommended HTTP security headers to protect against:
 * - Clickjacking (X-Frame-Options, CSP frame-ancestors)
 * - MIME-type sniffing (X-Content-Type-Options)
 * - XSS attacks (Content-Security-Policy)
 * - Information leakage (Referrer-Policy, Permissions-Policy)
 * - Insecure connections (Strict-Transport-Security)
 * - Cache poisoning (Cache-Control for sensitive pages)
 */
class SecurityHeadersMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var Response $response */
        $response = $next($request);

        // ── Anti-Clickjacking ─────────────────────────────────────
        $response->headers->set('X-Frame-Options', 'DENY');

        // ── MIME-type sniffing protection ──────────────────────────
        $response->headers->set('X-Content-Type-Options', 'nosniff');

        // ── XSS Protection (legacy browsers) ──────────────────────
        $response->headers->set('X-XSS-Protection', '1; mode=block');

        // ── Referrer Policy ───────────────────────────────────────
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        // ── Permissions Policy (restrict browser features) ────────
        $response->headers->set(
            'Permissions-Policy',
            'accelerometer=(), camera=(self), geolocation=(), gyroscope=(), magnetometer=(), microphone=(self), payment=(), usb=()'
        );

        // ── HSTS (force HTTPS) ────────────────────────────────────
        if (config('app.env') === 'production' || $request->isSecure()) {
            $response->headers->set(
                'Strict-Transport-Security',
                'max-age=31536000; includeSubDomains; preload'
            );
        }

        // ── Content Security Policy ───────────────────────────────
        // Relaxed for admin panel (CDN assets), strict for API
        if ($request->is('api/*')) {
            $response->headers->set(
                'Content-Security-Policy',
                "default-src 'none'; frame-ancestors 'none'"
            );
        } else {
            $response->headers->set(
                'Content-Security-Policy',
                implode('; ', [
                    "default-src 'self'",
                    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://cdn.jsdelivr.net",
                    "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://fonts.googleapis.com",
                    "font-src 'self' https://fonts.gstatic.com https://fonts.googleapis.com",
                    "img-src 'self' data: https:",
                    "connect-src 'self' wss: ws:",
                    "frame-ancestors 'none'",
                ])
            );
        }

        // ── Prevent caching of sensitive pages ────────────────────
        if ($request->is('admin/*') || $request->is('api/auth/*')) {
            $response->headers->set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
            $response->headers->set('Pragma', 'no-cache');
            $response->headers->set('Expires', '0');
        }

        // ── Cross-Origin policies ─────────────────────────────────
        $response->headers->set('Cross-Origin-Opener-Policy', 'same-origin');
        $response->headers->set('Cross-Origin-Resource-Policy', 'same-origin');

        return $response;
    }
}
