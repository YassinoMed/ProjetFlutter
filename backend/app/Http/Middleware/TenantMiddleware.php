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
     * Default tenant identifier used when no X-Tenant-Identifier header is provided.
     */
    private const DEFAULT_TENANT = 'mediconnect';

    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Skip tenant initialization for non-API routes and the tenants listing endpoint
        if (! $request->is('api/*') || $request->is('api/tenants')) {
            return $next($request);
        }

        // Use header if provided, otherwise fallback to default tenant
        $tenantId = $request->header('X-Tenant-Identifier', self::DEFAULT_TENANT);

        try {
            tenancy()->initialize($tenantId);
        } catch (\Exception $e) {
            return $this->respondError(
                'Invalid tenant identifier.',
                403,
                ['tenant' => ['Tenant matching identifier could not be found or initialized.']],
            );
        }

        return $next($request);
    }
}
