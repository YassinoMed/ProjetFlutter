<?php

namespace App\Services\Ops\Metrics;

use App\Enums\DocumentProcessingStatus;
use App\Jobs\ProcessDocumentJob;
use App\Models\DocumentProcessingJob;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Schema;

class MetricsCollectorService
{
    public function __construct(private readonly MetricsStore $store) {}

    public function collect(): string
    {
        $output = [];
        $definitions = (array) config('metrics.definitions', []);

        foreach ($definitions as $metric => $definition) {
            $type = (string) ($definition['type'] ?? 'gauge');
            $help = (string) ($definition['help'] ?? $metric);

            $output[] = sprintf('# HELP %s %s', $metric, $help);
            $output[] = sprintf('# TYPE %s %s', $metric, $type === 'histogram' ? 'histogram' : $type);

            if ($type === 'counter') {
                foreach ($this->store->readSeries('counter', $metric) as $series) {
                    $output[] = $this->renderSample($metric, $series['labels'], $series['value']);
                }
            } elseif ($type === 'gauge') {
                $seriesList = match ($metric) {
                    'mediconnect_queue_backlog_jobs' => $this->collectQueueBacklogSeries(),
                    'mediconnect_failed_jobs_records_total' => $this->collectFailedJobsSeries(),
                    'mediconnect_document_ai_failed_records_total' => $this->collectDocumentAiFailureSeries(),
                    default => $this->store->readSeries('gauge', $metric),
                };

                foreach ($seriesList as $series) {
                    $output[] = $this->renderSample($metric, $series['labels'], $series['value']);
                }
            } elseif ($type === 'histogram') {
                foreach ($this->store->readSeries('histogram_bucket', $metric) as $series) {
                    $labels = $series['labels'];
                    $bucketValue = $series['value'];
                    $output[] = $this->renderSample($metric.'_bucket', $labels, $bucketValue);
                }

                foreach ($this->store->readSeries('histogram_sum', $metric) as $series) {
                    $output[] = $this->renderSample($metric.'_sum', $series['labels'], $series['value']);
                }

                foreach ($this->store->readSeries('histogram_count', $metric) as $series) {
                    $output[] = $this->renderSample($metric.'_count', $series['labels'], $series['value']);
                }
            }

            $output[] = '';
        }

        return implode("\n", array_filter($output, static fn (?string $line): bool => $line !== null));
    }

    /**
     * @return array<int, array{labels: array<string, string>, value: float|int}>
     */
    private function collectQueueBacklogSeries(): array
    {
        $series = [];
        $queues = (array) config('metrics.queue_names', ['default']);

        foreach ($queues as $queue) {
            $queue = (string) $queue;
            $baseKey = 'queues:'.$queue;

            $series[] = [
                'labels' => ['queue' => $queue, 'state' => 'ready'],
                'value' => (float) Redis::llen($baseKey),
            ];

            $series[] = [
                'labels' => ['queue' => $queue, 'state' => 'reserved'],
                'value' => (float) Redis::zcard($baseKey.':reserved'),
            ];

            $series[] = [
                'labels' => ['queue' => $queue, 'state' => 'delayed'],
                'value' => (float) Redis::zcard($baseKey.':delayed'),
            ];
        }

        return $series;
    }

    /**
     * @return array<int, array{labels: array<string, string>, value: float|int}>
     */
    private function collectFailedJobsSeries(): array
    {
        if (! Schema::hasTable('failed_jobs')) {
            return [[
                'labels' => ['source' => 'database', 'table_present' => 'false'],
                'value' => 0,
            ]];
        }

        return [[
            'labels' => ['source' => 'database', 'table_present' => 'true'],
            'value' => (float) DB::table('failed_jobs')->count(),
        ]];
    }

    /**
     * @return array<int, array{labels: array<string, string>, value: float|int}>
     */
    private function collectDocumentAiFailureSeries(): array
    {
        if (! Schema::hasTable('document_processing_jobs')) {
            return [[
                'labels' => ['job' => class_basename(ProcessDocumentJob::class)],
                'value' => 0,
            ]];
        }

        $count = DocumentProcessingJob::query()
            ->where('job_type', ProcessDocumentJob::class)
            ->where('status', DocumentProcessingStatus::FAILED->value)
            ->count();

        return [[
            'labels' => ['job' => class_basename(ProcessDocumentJob::class)],
            'value' => (float) $count,
        ]];
    }

    private function renderSample(string $metric, array $labels, float|int $value): string
    {
        if ($labels === []) {
            return sprintf('%s %s', $metric, $this->formatValue($value));
        }

        ksort($labels);
        $labelSet = collect($labels)
            ->map(fn (string $labelValue, string $labelKey): string => sprintf('%s="%s"', $labelKey, $this->escapeLabelValue($labelValue)))
            ->implode(',');

        return sprintf('%s{%s} %s', $metric, $labelSet, $this->formatValue($value));
    }

    private function escapeLabelValue(string $value): string
    {
        return str_replace(['\\', '"', "\n"], ['\\\\', '\"', '\n'], $value);
    }

    private function formatValue(float|int $value): string
    {
        if (is_int($value) || fmod((float) $value, 1.0) === 0.0) {
            return (string) (int) $value;
        }

        return number_format((float) $value, 6, '.', '');
    }
}
