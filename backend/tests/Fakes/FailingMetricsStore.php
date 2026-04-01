<?php

namespace Tests\Fakes;

use App\Services\Ops\Metrics\MetricsStore;
use RuntimeException;

class FailingMetricsStore extends MetricsStore
{
    public function incrementCounter(string $metric, array $labels = [], float|int $value = 1): void
    {
        throw new RuntimeException('Metrics backend unavailable');
    }

    public function setGauge(string $metric, array $labels = [], float|int $value = 0): void
    {
        throw new RuntimeException('Metrics backend unavailable');
    }

    public function observeHistogram(string $metric, float $value, array $labels = []): void
    {
        throw new RuntimeException('Metrics backend unavailable');
    }

    public function putTemporaryValue(string $namespace, string $identifier, float|int|string $value, int $ttlSeconds = 86400): void
    {
        throw new RuntimeException('Metrics backend unavailable');
    }

    public function pullTemporaryValue(string $namespace, string $identifier): ?float
    {
        throw new RuntimeException('Metrics backend unavailable');
    }

    public function readSeries(string $type, string $metric): array
    {
        throw new RuntimeException('Metrics backend unavailable');
    }
}
