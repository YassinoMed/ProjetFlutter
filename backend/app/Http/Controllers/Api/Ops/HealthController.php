<?php

namespace App\Http\Controllers\Api\Ops;

use App\Http\Controllers\Controller;
use App\Services\Ops\HealthCheckService;
use Illuminate\Http\JsonResponse;

class HealthController extends Controller
{
    public function __construct(private readonly HealthCheckService $healthCheckService) {}

    public function live(): JsonResponse
    {
        return $this->respondSuccess(
            $this->healthCheckService->live(),
            'Service is alive'
        );
    }

    public function ready(): JsonResponse
    {
        $payload = $this->healthCheckService->ready();

        if ($payload['status'] !== 'ready') {
            return $this->respondError(
                'Service dependencies are not ready',
                503,
                [
                    'checks' => [$payload['checks']],
                ]
            );
        }

        return $this->respondSuccess(
            $payload,
            'Service is ready'
        );
    }
}
