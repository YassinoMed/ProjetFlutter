<?php

namespace Tests\Fakes;

use App\Services\Ops\Metrics\MetricsStore;

class InMemoryMetricsStore extends MetricsStore
{
    /**
     * @var array<string, array<string, float>>
     */
    private array $series = [];

    /**
     * @var array<string, float>
     */
    private array $temporaryValues = [];

    public function incrementCounter(string $metric, array $labels = [], float|int $value = 1): void
    {
        $this->increment('counter', $metric, $labels, (float) $value);
    }

    public function setGauge(string $metric, array $labels = [], float|int $value = 0): void
    {
        $this->series['gauge'][$metric][$this->encodeLabels($labels)] = (float) $value;
    }

    public function observeHistogram(string $metric, float $value, array $labels = []): void
    {
        $baseLabels = $this->normalizeLabels($labels);
        $buckets = (array) (config("metrics.definitions.{$metric}.buckets") ?? config('metrics.default_histogram_buckets', []));

        sort($buckets);

        foreach ($buckets as $bucket) {
            if ($value <= (float) $bucket) {
                $this->increment('histogram_bucket', $metric, [...$baseLabels, 'le' => $this->formatNumber((float) $bucket)], 1.0);
            }
        }

        $this->increment('histogram_bucket', $metric, [...$baseLabels, 'le' => '+Inf'], 1.0);
        $this->increment('histogram_sum', $metric, $baseLabels, $value);
        $this->increment('histogram_count', $metric, $baseLabels, 1.0);
    }

    public function putTemporaryValue(string $namespace, string $identifier, float|int|string $value, int $ttlSeconds = 86400): void
    {
        $this->temporaryValues[$namespace.':'.$identifier] = (float) $value;
    }

    public function pullTemporaryValue(string $namespace, string $identifier): ?float
    {
        $key = $namespace.':'.$identifier;
        $value = $this->temporaryValues[$key] ?? null;

        unset($this->temporaryValues[$key]);

        return $value;
    }

    public function readSeries(string $type, string $metric): array
    {
        $rows = $this->series[$type][$metric] ?? [];
        $series = [];

        foreach ($rows as $encodedLabels => $value) {
            $series[] = [
                'labels' => $this->decodeLabels($encodedLabels),
                'value' => $value,
            ];
        }

        return $series;
    }

    private function increment(string $type, string $metric, array $labels, float $value): void
    {
        $encodedLabels = $this->encodeLabels($labels);
        $this->series[$type][$metric][$encodedLabels] = ($this->series[$type][$metric][$encodedLabels] ?? 0.0) + $value;
    }

    private function encodeLabels(array $labels): string
    {
        return json_encode($this->normalizeLabels($labels), JSON_THROW_ON_ERROR);
    }

    private function decodeLabels(string $encodedLabels): array
    {
        if ($encodedLabels === '') {
            return [];
        }

        /** @var array<string, string> $decoded */
        $decoded = json_decode($encodedLabels, true, flags: JSON_THROW_ON_ERROR);

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
