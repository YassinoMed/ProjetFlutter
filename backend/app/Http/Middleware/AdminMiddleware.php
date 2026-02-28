<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Require authentication
        if (!auth()->check()) {
            return redirect()->route('admin.login');
        }

        // Require ADMIN role
        if (auth()->user()->role !== UserRole::ADMIN) {
            abort(403, 'Accès non autorisé. Réservé aux administrateurs.');
        }

        return $next($request);
    }
}
