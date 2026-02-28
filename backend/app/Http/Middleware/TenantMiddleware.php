<?php

namespace App\Http\Middleware;

use App\Traits\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TenantMiddleware
{
    use ApiResponse;

    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $requiresTenant = $request->is('api/*') && ! $request->is('api/auth/*');
        $tenantId = $request->header('X-Tenant-Identifier');

        if ($requiresTenant && (! is_string($tenantId) || $tenantId === '')) {
            return $this->respondError(
                'Tenant identifier is required.',
                400,
                ['tenant' => ['Missing X-Tenant-Identifier header.']],
            );
        }

        if (is_string($tenantId) && $tenantId !== '') {
            try {
                tenancy()->initialize($tenantId);
            } catch (\Exception $e) {
                return $this->respondError(
                    'Invalid tenant identifier.',
                    403,
                    ['tenant' => ['Tenant matching X-Tenant-Identifier could not be found or initialized.']],
                );
            }
        }

        return $next($request);
    }
}
