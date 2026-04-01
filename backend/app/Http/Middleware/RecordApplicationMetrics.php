<?php

namespace App\Http\Middleware;

use App\Services\Ops\Metrics\MetricsStore;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class RecordApplicationMetrics
{
    public function __construct(private readonly MetricsStore $metricsStore) {}

    public function handle(Request $request, Closure $next): Response
    {
        if (! (bool) config('metrics.enabled', true)) {
            return $next($request);
        }

        $path = ltrim($request->path(), '/');

        if ($this->shouldSkip($path)) {
            return $next($request);
        }

        $startedAt = microtime(true);

        /** @var Response $response */
        $response = $next($request);

        $durationSeconds = microtime(true) - $startedAt;
        $statusCode = $response->getStatusCode();
        $statusClass = $this->statusClass($statusCode);
        $route = $request->route()?->uri() ?? $request->path();
        $method = $request->method();

        $baseLabels = [
            'method' => $method,
            'route' => $route,
            'status_class' => $statusClass,
        ];

        try {
            $this->metricsStore->incrementCounter('mediconnect_http_requests_total', $baseLabels);
            $this->metricsStore->observeHistogram('mediconnect_http_request_duration_seconds', $durationSeconds, [
                'method' => $method,
                'route' => $route,
            ]);

            if ($statusCode >= 400) {
                $this->metricsStore->incrementCounter('mediconnect_http_errors_total', [
                    'method' => $method,
                    'route' => $route,
                    'status_code' => (string) $statusCode,
                    'status_class' => $statusClass,
                ]);
            }

            if ($request->is('api/auth/*') && in_array($statusCode, [401, 403, 422, 429], true)) {
                $this->metricsStore->incrementCounter('mediconnect_auth_failures_total', [
                    'route' => $route,
                    'failure_type' => $this->authFailureType($statusCode),
                ]);
            }
        } catch (Throwable $exception) {
            Log::warning('record_application_metrics_failed', [
                'message' => $exception->getMessage(),
                'exception' => $exception::class,
                'route' => $route,
                'method' => $method,
            ]);
        }

        return $response;
    }

    private function shouldSkip(string $path): bool
    {
        return in_array($path, config('metrics.exclude_paths', []), true);
    }

    private function statusClass(int $statusCode): string
    {
        return match (true) {
            $statusCode >= 500 => '5xx',
            $statusCode >= 400 => '4xx',
            $statusCode >= 300 => '3xx',
            $statusCode >= 200 => '2xx',
            default => '1xx',
        };
    }

    private function authFailureType(int $statusCode): string
    {
        return match ($statusCode) {
            401 => 'unauthenticated',
            403 => 'forbidden',
            422 => 'validation',
            429 => 'rate_limited',
            default => 'other',
        };
    }
}
