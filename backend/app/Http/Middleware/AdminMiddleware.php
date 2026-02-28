<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Admin Middleware – Multi-layered security for admin panel access.
 *
 * Checks:
 * 1. User is authenticated (session-based via 'web' guard)
 * 2. User has ADMIN role
 * 3. Session fingerprint matches (prevents session hijacking)
 * 4. Logs all admin access for audit trail
 */
class AdminMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // ── 1. Require authentication ─────────────────────────────
        if (!auth('web')->check()) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Unauthenticated'], 401);
            }
            return redirect()->route('admin.login');
        }

        $user = auth('web')->user();

        // ── 2. Require ADMIN role ─────────────────────────────────
        if ($user->role !== UserRole::ADMIN) {
            Log::channel('security')->warning('Unauthorized admin access attempt', [
                'user_id' => $user->id,
                'email' => $user->email,
                'role' => $user->role?->value ?? $user->role,
                'ip' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'uri' => $request->getRequestUri(),
            ]);

            abort(403, 'Accès non autorisé. Réservé aux administrateurs.');
        }

        // ── 3. Session fingerprint validation ─────────────────────
        $fingerprint = $this->generateFingerprint($request);
        $storedFingerprint = session('admin_fingerprint');

        if ($storedFingerprint === null) {
            // First request – store fingerprint
            session(['admin_fingerprint' => $fingerprint]);
        } elseif ($storedFingerprint !== $fingerprint) {
            // Fingerprint mismatch → possible session hijacking
            Log::channel('security')->alert('Admin session fingerprint mismatch (possible hijacking)', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip' => $request->ip(),
                'stored_fingerprint' => $storedFingerprint,
                'current_fingerprint' => $fingerprint,
            ]);

            auth('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('admin.login')
                ->with('error', 'Session invalide. Veuillez vous reconnecter.');
        }

        // ── 4. Audit logging ──────────────────────────────────────
        Log::channel('single')->debug('[ADMIN ACCESS]', [
            'user_id' => $user->id,
            'email' => $user->email,
            'ip' => $request->ip(),
            'method' => $request->method(),
            'uri' => $request->getRequestUri(),
        ]);

        return $next($request);
    }

    /**
     * Generate a browser fingerprint based on stable headers.
     */
    private function generateFingerprint(Request $request): string
    {
        return hash('sha256', implode('|', [
            $request->ip(),
            $request->userAgent() ?? '',
            $request->header('Accept-Language', ''),
        ]));
    }
}
