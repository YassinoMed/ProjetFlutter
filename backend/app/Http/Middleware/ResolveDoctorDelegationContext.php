<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use App\Services\DelegationContextService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ResolveDoctorDelegationContext
{
    public function __construct(private readonly DelegationContextService $delegationContextService) {}

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user !== null && $user->role === UserRole::SECRETARY) {
            $delegation = $this->delegationContextService->resolveForRequest($request);

            if ($delegation !== null) {
                $request->attributes->set('doctor_delegation', $delegation);
            }
        }

        return $next($request);
    }
}
