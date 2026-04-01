<?php

return [
    'enabled' => env('METRICS_ENABLED', true),
    'token' => env('METRICS_TOKEN'),
    'redis_connection' => env('METRICS_REDIS_CONNECTION', env('REDIS_CACHE_CONNECTION', 'cache')),
    'queue_names' => array_values(array_filter(array_map(
        static fn (string $queue): string => trim($queue),
        explode(',', (string) env('METRICS_QUEUE_NAMES', env('REDIS_QUEUE', 'default'))),
    ))),
    'exclude_paths' => [
        'up',
        'api/ops/health/live',
        'api/ops/health/ready',
        'api/ops/metrics',
    ],
    'default_histogram_buckets' => [
        0.05,
        0.1,
        0.25,
        0.5,
        1,
        2.5,
        5,
        10,
    ],
    'definitions' => [
        'mediconnect_http_requests_total' => [
            'type' => 'counter',
            'help' => 'Total HTTP requests handled by Laravel API.',
        ],
        'mediconnect_http_errors_total' => [
            'type' => 'counter',
            'help' => 'Total HTTP error responses grouped by route and status.',
        ],
        'mediconnect_auth_failures_total' => [
            'type' => 'counter',
            'help' => 'Total authentication and authorization failures.',
        ],
        'mediconnect_http_request_duration_seconds' => [
            'type' => 'histogram',
            'help' => 'HTTP request duration in seconds.',
        ],
        'mediconnect_job_processed_total' => [
            'type' => 'counter',
            'help' => 'Total successfully processed queued jobs.',
        ],
        'mediconnect_job_failed_total' => [
            'type' => 'counter',
            'help' => 'Total failed queued jobs.',
        ],
        'mediconnect_job_duration_seconds' => [
            'type' => 'histogram',
            'help' => 'Queued job processing duration in seconds.',
        ],
        'mediconnect_business_job_failures_total' => [
            'type' => 'counter',
            'help' => 'Failed queued jobs grouped by business domain.',
        ],
        'mediconnect_queue_backlog_jobs' => [
            'type' => 'gauge',
            'help' => 'Current Redis queue backlog grouped by queue and state.',
        ],
        'mediconnect_failed_jobs_records_total' => [
            'type' => 'gauge',
            'help' => 'Current number of persisted failed jobs records.',
        ],
        'mediconnect_document_ai_failed_records_total' => [
            'type' => 'gauge',
            'help' => 'Current number of failed document AI processing records.',
        ],
    ],
];
