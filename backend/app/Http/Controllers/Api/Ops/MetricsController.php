<?php

namespace App\Http\Controllers\Api\Ops;

use App\Http\Controllers\Controller;
use App\Services\Ops\Metrics\MetricsCollectorService;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class MetricsController extends Controller
{
    public function __construct(private readonly MetricsCollectorService $collectorService) {}

    public function __invoke(Request $request): Response
    {
        abort_unless((bool) config('metrics.enabled', true), 404);

        $configuredToken = (string) config('metrics.token', '');
        $providedToken = (string) ($request->query('token') ?? $request->header('X-Metrics-Token') ?? '');

        if ($configuredToken !== '' && ! hash_equals($configuredToken, $providedToken)) {
            abort(403, 'Forbidden');
        }

        return response(
            $this->collectorService->collect(),
            200,
            ['Content-Type' => 'text/plain; version=0.0.4; charset=utf-8']
        );
    }
}
