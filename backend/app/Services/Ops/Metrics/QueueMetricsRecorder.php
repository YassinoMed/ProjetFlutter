<?php

namespace App\Services\Ops\Metrics;

use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Queue\Events\JobProcessing;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class QueueMetricsRecorder
{
    public function __construct(private readonly MetricsStore $metricsStore) {}

    public function onJobProcessing(JobProcessing $event): void
    {
        $this->recordSafely(fn () => $this->metricsStore->putTemporaryValue(
            'job_started_at',
            $this->jobIdentifier($event->job),
            microtime(true)
        ));
    }

    public function onJobProcessed(JobProcessed $event): void
    {
        $this->recordSafely(function () use ($event): void {
            $jobClass = $this->jobClassName($event->job);
            $queue = $event->job->getQueue() ?: $event->connectionName ?: 'default';
            $durationSeconds = $this->resolveDurationSeconds($event->job);

            $this->metricsStore->incrementCounter('mediconnect_job_processed_total', [
                'job' => class_basename($jobClass),
                'queue' => $queue,
            ]);

            if ($durationSeconds !== null) {
                $this->metricsStore->observeHistogram('mediconnect_job_duration_seconds', $durationSeconds, [
                    'job' => class_basename($jobClass),
                    'queue' => $queue,
                    'status' => 'processed',
                    'domain' => $this->classifyDomain($jobClass),
                ]);
            }
        });
    }

    public function onJobFailed(JobFailed $event): void
    {
        $this->recordSafely(function () use ($event): void {
            $jobClass = $this->jobClassName($event->job);
            $queue = $event->job->getQueue() ?: $event->connectionName ?: 'default';
            $domain = $this->classifyDomain($jobClass);
            $durationSeconds = $this->resolveDurationSeconds($event->job);

            $this->metricsStore->incrementCounter('mediconnect_job_failed_total', [
                'job' => class_basename($jobClass),
                'queue' => $queue,
            ]);

            $this->metricsStore->incrementCounter('mediconnect_business_job_failures_total', [
                'domain' => $domain,
                'job' => class_basename($jobClass),
                'queue' => $queue,
            ]);

            if ($durationSeconds !== null) {
                $this->metricsStore->observeHistogram('mediconnect_job_duration_seconds', $durationSeconds, [
                    'job' => class_basename($jobClass),
                    'queue' => $queue,
                    'status' => 'failed',
                    'domain' => $domain,
                ]);
            }
        });
    }

    private function recordSafely(callable $callback): void
    {
        try {
            $callback();
        } catch (Throwable $exception) {
            Log::warning('queue_metrics_recording_failed', [
                'message' => $exception->getMessage(),
                'exception' => $exception::class,
            ]);
        }
    }

    private function resolveDurationSeconds(object $job): ?float
    {
        $startedAt = $this->metricsStore->pullTemporaryValue('job_started_at', $this->jobIdentifier($job));

        if ($startedAt === null) {
            return null;
        }

        return max(0.0, microtime(true) - $startedAt);
    }

    private function jobIdentifier(object $job): string
    {
        if (method_exists($job, 'getJobId') && $job->getJobId() !== null) {
            return (string) $job->getJobId();
        }

        if (method_exists($job, 'payload')) {
            return sha1((string) json_encode($job->payload()));
        }

        return spl_object_hash($job);
    }

    private function jobClassName(object $job): string
    {
        if (method_exists($job, 'resolveName')) {
            return (string) $job->resolveName();
        }

        return $job::class;
    }

    private function classifyDomain(string $jobClass): string
    {
        $class = Str::lower($jobClass);

        return match (true) {
            str_contains($class, 'document') => 'document_ai',
            str_contains($class, 'consultationsummary'),
            str_contains($class, 'postconsultation'),
            str_contains($class, 'followup') => 'post_consultation',
            str_contains($class, 'teleconsultation'),
            str_contains($class, 'call') => 'teleconsultation',
            str_contains($class, 'appointment') => 'appointments',
            str_contains($class, 'notification'),
            str_contains($class, 'reminder') => 'notifications',
            default => 'other',
        };
    }
}
