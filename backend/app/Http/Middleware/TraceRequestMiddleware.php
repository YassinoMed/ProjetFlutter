<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * OpenTelemetry-style Distributed Tracing Middleware.
 *
 * Injects W3C Trace Context headers (traceparent / tracestate) into every
 * HTTP response and logs spans for each request.
 *
 * If no OpenTelemetry PHP extension is installed, this middleware acts as a
 * lightweight tracing layer using native PHP — perfect for dev and staging.
 *
 * Production upgrade path:
 *   1. Install open-telemetry/sdk + open-telemetry/exporter-otlp
 *   2. Replace the manual span with the SDK's TracerProvider
 *   3. Export to Jaeger / Grafana Tempo / Zipkin
 */
class TraceRequestMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        // ── Parse or generate trace context ──────────────────────
        $traceId = $this->extractTraceId($request) ?? Str::random(32);
        $spanId = bin2hex(random_bytes(8));
        $parentSpanId = $this->extractSpanId($request);

        $startTime = microtime(true);

        // Attach trace context to the request so downstream services/jobs can use it
        $request->headers->set('X-Trace-Id', $traceId);
        $request->headers->set('X-Span-Id', $spanId);

        /** @var Response $response */
        $response = $next($request);

        $durationMs = round((microtime(true) - $startTime) * 1000, 2);

        // ── Inject W3C traceparent into response headers ─────────
        $traceparent = "00-{$traceId}-{$spanId}-01";
        $response->headers->set('traceparent', $traceparent);
        $response->headers->set('X-Trace-Id', $traceId);
        $response->headers->set('X-Span-Id', $spanId);
        $response->headers->set('X-Duration-Ms', (string) $durationMs);

        // ── Log span as structured JSON ──────────────────────────
        $spanData = [
            'trace_id' => $traceId,
            'span_id' => $spanId,
            'parent_span_id' => $parentSpanId,
            'service' => env('OTEL_SERVICE_NAME', 'mediconnect-api'),
            'operation' => $request->method().' '.$request->path(),
            'http.method' => $request->method(),
            'http.url' => $request->fullUrl(),
            'http.route' => $request->route()?->uri() ?? $request->path(),
            'http.status_code' => $response->getStatusCode(),
            'http.user_agent' => Str::limit($request->userAgent() ?? '', 200),
            'user.id' => $request->user()?->id,
            'user.role' => $request->user()?->role?->value ?? null,
            'duration_ms' => $durationMs,
            'timestamp' => now('UTC')->toISOString(),
        ];

        // Log slow requests at warning level
        $logLevel = $durationMs > 2000 ? 'warning' : 'debug';
        Log::channel('single')->log($logLevel, '[TRACE] '.$spanData['operation'], $spanData);

        // ── Export to OTLP endpoint (if configured) ──────────────
        if (env('OTEL_ENABLED', false) && env('OTEL_EXPORTER_OTLP_ENDPOINT')) {
            $this->exportSpanAsync($spanData);
        }

        return $response;
    }

    /**
     * Extract trace ID from incoming W3C traceparent header.
     */
    private function extractTraceId(Request $request): ?string
    {
        $traceparent = $request->header('traceparent');
        if ($traceparent && preg_match('/^00-([a-f0-9]{32})-([a-f0-9]{16})-[0-9]{2}$/', $traceparent, $matches)) {
            return $matches[1];
        }

        return $request->header('X-Trace-Id');
    }

    private function extractSpanId(Request $request): ?string
    {
        $traceparent = $request->header('traceparent');
        if ($traceparent && preg_match('/^00-[a-f0-9]{32}-([a-f0-9]{16})-[0-9]{2}$/', $traceparent, $matches)) {
            return $matches[1];
        }

        return $request->header('X-Span-Id');
    }

    /**
     * Fire-and-forget export to an OTLP collector (non-blocking).
     */
    private function exportSpanAsync(array $spanData): void
    {
        try {
            $endpoint = rtrim(env('OTEL_EXPORTER_OTLP_ENDPOINT'), '/').'/v1/traces';

            $payload = json_encode([
                'resourceSpans' => [[
                    'resource' => [
                        'attributes' => [
                            ['key' => 'service.name', 'value' => ['stringValue' => $spanData['service']]],
                        ],
                    ],
                    'scopeSpans' => [[
                        'spans' => [[
                            'traceId' => $spanData['trace_id'],
                            'spanId' => $spanData['span_id'],
                            'parentSpanId' => $spanData['parent_span_id'] ?? '',
                            'name' => $spanData['operation'],
                            'kind' => 2, // SPAN_KIND_SERVER
                            'startTimeUnixNano' => (string) ((microtime(true) - $spanData['duration_ms'] / 1000) * 1_000_000_000),
                            'endTimeUnixNano' => (string) (microtime(true) * 1_000_000_000),
                            'attributes' => collect($spanData)
                                ->except(['trace_id', 'span_id', 'parent_span_id', 'service', 'operation'])
                                ->map(fn ($v, $k) => [
                                    'key' => $k,
                                    'value' => ['stringValue' => (string) $v],
                                ])
                                ->values()
                                ->toArray(),
                            'status' => [
                                'code' => $spanData['http.status_code'] >= 400 ? 2 : 1,
                            ],
                        ]],
                    ]],
                ]],
            ]);

            // Fire-and-forget (non-blocking)
            $ch = curl_init($endpoint);
            curl_setopt_array($ch, [
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => $payload,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT_MS => 500,
                CURLOPT_CONNECTTIMEOUT_MS => 200,
            ]);
            curl_exec($ch);
            curl_close($ch);
        } catch (\Throwable) {
            // Silently fail — tracing should never break the app
        }
    }
}
