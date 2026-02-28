<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Show admin login form.
     * Redirects to dashboard if already authenticated as admin.
     */
    public function showLoginForm()
    {
        if (Auth::guard('web')->check() && Auth::guard('web')->user()->role === UserRole::ADMIN) {
            return redirect()->route('admin.dashboard');
        }

        return view('admin.auth.login');
    }

    /**
     * Handle admin login with brute-force protection.
     *
     * Security measures:
     * 1. Rate limiting (5 attempts per minute per email+IP)
     * 2. Input validation
     * 3. Role-based access control
     * 4. Session regeneration on success
     * 5. Security audit logging
     */
    public function login(Request $request)
    {
        // ── 1. Rate limiting ──────────────────────────────────────
        $throttleKey = $this->throttleKey($request);

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = RateLimiter::availableIn($throttleKey);

            Log::channel('security')->warning('Admin login rate limit exceeded', [
                'email' => $request->input('email'),
                'ip' => $request->ip(),
                'retry_after' => $seconds,
            ]);

            throw ValidationException::withMessages([
                'email' => "Trop de tentatives de connexion. Réessayez dans {$seconds} secondes.",
            ]);
        }

        // ── 2. Validate input ─────────────────────────────────────
        $credentials = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'password' => ['required', 'string', 'min:8', 'max:255'],
        ]);

        // Normalize email
        $credentials['email'] = Str::lower(trim($credentials['email']));

        // ── 3. Attempt authentication ─────────────────────────────
        if (Auth::guard('web')->attempt($credentials, $request->boolean('remember'))) {
            $user = Auth::guard('web')->user();

            // ── 4. Verify ADMIN role ──────────────────────────────
            if ($user->role !== UserRole::ADMIN) {
                Auth::guard('web')->logout();

                RateLimiter::hit($throttleKey, 60);

                Log::channel('security')->warning('Non-admin attempted admin login', [
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'role' => $user->role?->value ?? $user->role,
                    'ip' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                ]);

                return back()->withErrors([
                    'email' => 'Accès refusé. Vous ne disposez pas des privilèges administrateur.',
                ]);
            }

            // ── 5. Success – regenerate session ───────────────────
            $request->session()->regenerate();
            RateLimiter::clear($throttleKey);

            Log::channel('security')->info('Admin login successful', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip' => $request->ip(),
                'user_agent' => $request->userAgent(),
            ]);

            return redirect()->intended(route('admin.dashboard'));
        }

        // ── 6. Failed – increment rate limiter ────────────────────
        RateLimiter::hit($throttleKey, 60);

        Log::channel('security')->notice('Admin login failed', [
            'email' => $credentials['email'],
            'ip' => $request->ip(),
            'attempts_remaining' => RateLimiter::retriesLeft($throttleKey, 5),
        ]);

        return back()->withErrors([
            'email' => 'Identifiants invalides.',
        ])->onlyInput('email');
    }

    /**
     * Handle admin logout with full session cleanup.
     */
    public function logout(Request $request)
    {
        $user = Auth::guard('web')->user();

        if ($user) {
            Log::channel('security')->info('Admin logout', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip' => $request->ip(),
            ]);
        }

        Auth::guard('web')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }

    /**
     * Generate a unique throttle key combining email and IP.
     */
    private function throttleKey(Request $request): string
    {
        return 'admin-login:' . Str::lower(trim($request->input('email', ''))) . ':' . $request->ip();
    }
}
