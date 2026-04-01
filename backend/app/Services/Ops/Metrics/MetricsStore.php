<?php

namespace App\Services\Ops\Metrics;

use Illuminate\Redis\Connections\Connection;
use Illuminate\Support\Facades\Redis;

class MetricsStore
{
    private const PREFIX = 'mediconnect:metrics';

    public function incrementCounter(string $metric, array $labels = [], float|int $value = 1): void
    {
        $this->redis()->hIncrByFloat(
            $this->key('counter', $metric),
            $this->encodeLabels($labels),
            (float) $value
        );
    }

    public function setGauge(string $metric, array $labels = [], float|int $value = 0): void
    {
        $this->redis()->hSet(
            $this->key('gauge', $metric),
            $this->encodeLabels($labels),
            (string) $value
        );
    }

    public function observeHistogram(string $metric, float $value, array $labels = []): void
    {
        $baseLabels = $this->normalizeLabels($labels);
        $baseField = $this->encodeLabels($baseLabels);
        $buckets = (array) (config("metrics.definitions.{$metric}.buckets") ?? config('metrics.default_histogram_buckets', []));

        sort($buckets);

        foreach ($buckets as $bucket) {
            if ($value <= (float) $bucket) {
                $this->redis()->hIncrByFloat(
                    $this->key('histogram_bucket', $metric),
                    $this->encodeLabels([...$baseLabels, 'le' => $this->formatNumber((float) $bucket)]),
                    1.0
                );
            }
        }

        $this->redis()->hIncrByFloat(
            $this->key('histogram_bucket', $metric),
            $this->encodeLabels([...$baseLabels, 'le' => '+Inf']),
            1.0
        );

        $this->redis()->hIncrByFloat($this->key('histogram_sum', $metric), $baseField, $value);
        $this->redis()->hIncrByFloat($this->key('histogram_count', $metric), $baseField, 1.0);
    }

    public function putTemporaryValue(string $namespace, string $identifier, float|int|string $value, int $ttlSeconds = 86400): void
    {
        $key = sprintf('%s:tmp:%s:%s', self::PREFIX, $namespace, $identifier);
        $this->redis()->setex($key, $ttlSeconds, (string) $value);
    }

    public function pullTemporaryValue(string $namespace, string $identifier): ?float
    {
        $key = sprintf('%s:tmp:%s:%s', self::PREFIX, $namespace, $identifier);
        $value = $this->redis()->getDel($key);

        return $value === null ? null : (float) $value;
    }

    public function readSeries(string $type, string $metric): array
    {
        $rows = $this->redis()->hGetAll($this->key($type, $metric));
        $series = [];

        foreach ($rows as $field => $value) {
            $series[] = [
                'labels' => $this->decodeLabels((string) $field),
                'value' => (float) $value,
            ];
        }

        return $series;
    }

    private function redis(): Connection
    {
        /** @var Connection $connection */
        $connection = Redis::connection((string) config('metrics.redis_connection', 'cache'));

        return $connection;
    }

    private function key(string $type, string $metric): string
    {
        return sprintf('%s:%s:%s', self::PREFIX, $type, $metric);
    }

    private function encodeLabels(array $labels): string
    {
        return json_encode($this->normalizeLabels($labels), JSON_THROW_ON_ERROR);
    }

    private function decodeLabels(string $encoded): array
    {
        if ($encoded === '') {
            return [];
        }

        /** @var array<string, string> $decoded */
        $decoded = json_decode($encoded, true, flags: JSON_THROW_ON_ERROR);

        return $decoded;
    }

    private function normalizeLabels(array $labels): array
    {
        $normalized = [];

        foreach ($labels as $key => $value) {
            if ($value === null || $value === '') {
                continue;
            }

            $normalized[(string) $key] = (string) $value;
        }

        ksort($normalized);

        return $normalized;
    }

    private function formatNumber(float $value): string
    {
        return rtrim(rtrim(number_format($value, 6, '.', ''), '0'), '.');
    }
}
