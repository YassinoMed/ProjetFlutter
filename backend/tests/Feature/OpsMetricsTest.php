<?php

namespace Tests\Feature;

use App\Enums\DocumentProcessingStatus;
use App\Jobs\ProcessDocumentJob;
use App\Jobs\SendAppointmentReminders;
use App\Models\Document;
use App\Models\DocumentProcessingJob;
use App\Models\User;
use App\Services\Ops\Metrics\MetricsStore;
use Illuminate\Contracts\Queue\Job as QueueJobContract;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Queue\Events\JobProcessing;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Mockery;
use RuntimeException;
use Tests\Concerns\UsesTenantMigrations;
use Tests\Fakes\InMemoryMetricsStore;
use Tests\TestCase;

class OpsMetricsTest extends TestCase
{
    use UsesTenantMigrations;

    private InMemoryMetricsStore $metricsStore;

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('app.key', 'base64:'.base64_encode(random_bytes(32)));
        config()->set('metrics.enabled', true);
        config()->set('metrics.token', 'test-metrics-token');
        config()->set('metrics.queue_names', ['default']);
        config()->set('metrics.redis_connection', 'cache');

        $this->bootTenantSchema();
        $this->registerTestRoutes();

        $this->metricsStore = new InMemoryMetricsStore();
        $this->app->instance(MetricsStore::class, $this->metricsStore);
        $this->app->forgetInstance(\App\Services\Ops\Metrics\QueueMetricsRecorder::class);
    }

    public function test_metrics_endpoint_refuses_access_without_token(): void
    {
        $this->get('/api/ops/metrics')
            ->assertForbidden();
    }

    public function test_metrics_endpoint_allows_access_with_valid_token_and_returns_prometheus_format(): void
    {
        $this->mockQueueBacklog();

        $response = $this->get('/api/ops/metrics?token=test-metrics-token');

        $response->assertOk();
        $this->assertSame('text/plain; version=0.0.4; charset=utf-8', $response->headers->get('Content-Type'));
        $response->assertSee('# HELP mediconnect_http_requests_total Total HTTP requests handled by Laravel API.', false);
        $response->assertSee('# TYPE mediconnect_http_request_duration_seconds histogram', false);
        $response->assertSee('mediconnect_queue_backlog_jobs{queue="default",state="ready"} 0', false);
    }

    public function test_http_metrics_increment_for_2xx_4xx_and_5xx_responses(): void
    {
        $this->getJson('/api/test/metrics/success')->assertOk();
        $this->getJson('/api/test/metrics/missing')->assertNotFound();
        $this->getJson('/api/test/metrics/failure')->assertStatus(500);

        $requestSeries = $this->metricsStore->readSeries('counter', 'mediconnect_http_requests_total');
        $errorSeries = $this->metricsStore->readSeries('counter', 'mediconnect_http_errors_total');

        $this->assertSame(1.0, $this->seriesValue($requestSeries, [
            'method' => 'GET',
            'route' => 'api/test/metrics/success',
            'status_class' => '2xx',
        ]));
        $this->assertSame(1.0, $this->seriesValue($requestSeries, [
            'method' => 'GET',
            'route' => 'api/test/metrics/missing',
            'status_class' => '4xx',
        ]));
        $this->assertSame(1.0, $this->seriesValue($requestSeries, [
            'method' => 'GET',
            'route' => 'api/test/metrics/failure',
            'status_class' => '5xx',
        ]));

        $this->assertSame(1.0, $this->seriesValue($errorSeries, [
            'method' => 'GET',
            'route' => 'api/test/metrics/missing',
            'status_code' => '404',
            'status_class' => '4xx',
        ]));
        $this->assertSame(1.0, $this->seriesValue($errorSeries, [
            'method' => 'GET',
            'route' => 'api/test/metrics/failure',
            'status_code' => '500',
            'status_class' => '5xx',
        ]));
    }

    public function test_auth_failure_metrics_increment_for_401_and_422_cases(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();
        $this->postJson('/api/auth/login', [])->assertStatus(422);

        $series = $this->metricsStore->readSeries('counter', 'mediconnect_auth_failures_total');

        $this->assertSame(1.0, $this->seriesValue($series, [
            'route' => 'api/auth/me',
            'failure_type' => 'unauthenticated',
        ]));
        $this->assertSame(1.0, $this->seriesValue($series, [
            'route' => 'api/auth/login',
            'failure_type' => 'validation',
        ]));
    }

    public function test_queue_processed_metrics_and_duration_are_recorded(): void
    {
        $job = $this->makeQueueJobMock('job-processed-1', 'default', SendAppointmentReminders::class);

        Event::dispatch(new JobProcessing('redis', $job));
        usleep(10_000);
        Event::dispatch(new JobProcessed('redis', $job));

        $processedSeries = $this->metricsStore->readSeries('counter', 'mediconnect_job_processed_total');
        $durationCountSeries = $this->metricsStore->readSeries('histogram_count', 'mediconnect_job_duration_seconds');
        $durationSumSeries = $this->metricsStore->readSeries('histogram_sum', 'mediconnect_job_duration_seconds');

        $this->assertSame(1.0, $this->seriesValue($processedSeries, [
            'job' => 'SendAppointmentReminders',
            'queue' => 'default',
        ]));
        $this->assertSame(1.0, $this->seriesValue($durationCountSeries, [
            'domain' => 'appointments',
            'job' => 'SendAppointmentReminders',
            'queue' => 'default',
            'status' => 'processed',
        ]));
        $this->assertGreaterThan(0.0, $this->seriesValue($durationSumSeries, [
            'domain' => 'appointments',
            'job' => 'SendAppointmentReminders',
            'queue' => 'default',
            'status' => 'processed',
        ]));
    }

    public function test_queue_failed_metrics_and_duration_are_recorded(): void
    {
        $job = $this->makeQueueJobMock('job-failed-1', 'default', ProcessDocumentJob::class);

        Event::dispatch(new JobProcessing('redis', $job));
        usleep(10_000);
        Event::dispatch(new JobFailed('redis', $job, new RuntimeException('Processing failed')));

        $failedSeries = $this->metricsStore->readSeries('counter', 'mediconnect_job_failed_total');
        $businessSeries = $this->metricsStore->readSeries('counter', 'mediconnect_business_job_failures_total');
        $durationCountSeries = $this->metricsStore->readSeries('histogram_count', 'mediconnect_job_duration_seconds');

        $this->assertSame(1.0, $this->seriesValue($failedSeries, [
            'job' => 'ProcessDocumentJob',
            'queue' => 'default',
        ]));
        $this->assertSame(1.0, $this->seriesValue($businessSeries, [
            'domain' => 'document_ai',
            'job' => 'ProcessDocumentJob',
            'queue' => 'default',
        ]));
        $this->assertSame(1.0, $this->seriesValue($durationCountSeries, [
            'domain' => 'document_ai',
            'job' => 'ProcessDocumentJob',
            'queue' => 'default',
            'status' => 'failed',
        ]));
    }

    public function test_metrics_endpoint_exposes_queue_backlog_values(): void
    {
        $this->mockQueueBacklog(7, 2, 1);

        $response = $this->get('/api/ops/metrics?token=test-metrics-token');

        $response->assertOk();
        $response->assertSee('mediconnect_queue_backlog_jobs{queue="default",state="ready"} 7', false);
        $response->assertSee('mediconnect_queue_backlog_jobs{queue="default",state="reserved"} 2', false);
        $response->assertSee('mediconnect_queue_backlog_jobs{queue="default",state="delayed"} 1', false);
    }

    public function test_metrics_endpoint_exposes_document_ai_failed_records(): void
    {
        $this->mockQueueBacklog();

        $user = User::factory()->create(['role' => 'PATIENT']);

        $document = Document::query()->create([
            'patient_user_id' => $user->id,
            'uploaded_by_user_id' => $user->id,
            'title' => 'Analyse test',
            'original_filename' => 'analyse.pdf',
            'mime_type' => 'application/pdf',
            'file_extension' => 'pdf',
            'file_size_bytes' => 1024,
            'storage_disk' => 'local',
            'storage_path' => 'medical-documents/test/analyse.pdf',
            'sha256_checksum' => hash('sha256', 'analyse'),
        ]);

        DocumentProcessingJob::query()->create([
            'document_id' => $document->id,
            'job_type' => ProcessDocumentJob::class,
            'queue_name' => 'default',
            'attempt' => 1,
            'status' => DocumentProcessingStatus::FAILED->value,
            'failed_at_utc' => now('UTC'),
            'error_code' => 'RuntimeException',
            'error_message_sanitized' => 'No readable text extracted',
        ]);

        $response = $this->get('/api/ops/metrics?token=test-metrics-token');

        $response->assertOk();
        $response->assertSee('mediconnect_document_ai_failed_records_total{job="ProcessDocumentJob"} 1', false);
    }

    public function test_metrics_endpoint_exposes_failed_jobs_table_count_when_present(): void
    {
        $this->mockQueueBacklog();

        $this->createFailedJobsTableIfMissing();

        \DB::table('failed_jobs')->insert([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'connection' => 'redis',
            'queue' => 'default',
            'payload' => json_encode(['job' => 'TestJob'], JSON_THROW_ON_ERROR),
            'exception' => 'RuntimeException: Test',
            'failed_at' => now(),
        ]);

        $response = $this->get('/api/ops/metrics?token=test-metrics-token');

        $response->assertOk();
        $response->assertSee('mediconnect_failed_jobs_records_total{source="database",table_present="true"} 1', false);
    }

    public function test_metrics_store_is_reset_between_tests(): void
    {
        $this->mockQueueBacklog();

        $response = $this->get('/api/ops/metrics?token=test-metrics-token');

        $response->assertOk();
        $response->assertDontSee('mediconnect_http_requests_total{', false);
        $this->assertSame([], $this->metricsStore->readSeries('counter', 'mediconnect_http_requests_total'));
    }

    private function registerTestRoutes(): void
    {
        Route::middleware('api')->prefix('api/test/metrics')->group(function (): void {
            Route::get('/success', fn () => response()->json(['ok' => true]));
            Route::get('/failure', function () {
                throw new RuntimeException('Synthetic metrics failure');
            });
        });
    }

    private function mockQueueBacklog(int $ready = 0, int $reserved = 0, int $delayed = 0): void
    {
        Redis::shouldReceive('llen')
            ->with('queues:default')
            ->zeroOrMoreTimes()
            ->andReturn($ready);

        Redis::shouldReceive('zcard')
            ->with('queues:default:reserved')
            ->zeroOrMoreTimes()
            ->andReturn($reserved);

        Redis::shouldReceive('zcard')
            ->with('queues:default:delayed')
            ->zeroOrMoreTimes()
            ->andReturn($delayed);
    }

    private function makeQueueJobMock(string $jobId, string $queue, string $resolvedName): QueueJobContract
    {
        /** @var QueueJobContract&\Mockery\MockInterface $job */
        $job = Mockery::mock(QueueJobContract::class);
        $job->shouldReceive('getJobId')->andReturn($jobId);
        $job->shouldReceive('getQueue')->andReturn($queue);
        $job->shouldReceive('resolveName')->andReturn($resolvedName);
        $job->shouldReceive('payload')->andReturn(['uuid' => $jobId, 'displayName' => $resolvedName]);

        return $job;
    }

    /**
     * @param  array<int, array{labels: array<string, string>, value: float}>  $series
     */
    private function seriesValue(array $series, array $expectedLabels): float
    {
        foreach ($series as $item) {
            $labels = $item['labels'];
            $matches = true;

            foreach ($expectedLabels as $key => $value) {
                if (($labels[$key] ?? null) !== $value) {
                    $matches = false;
                    break;
                }
            }

            if ($matches) {
                return $item['value'];
            }
        }

        $this->fail('Metric series not found for labels: '.json_encode($expectedLabels, JSON_THROW_ON_ERROR));
    }

    private function createFailedJobsTableIfMissing(): void
    {
        if (Schema::hasTable('failed_jobs')) {
            return;
        }

        Schema::create('failed_jobs', function (Blueprint $table): void {
            $table->id();
            $table->string('uuid')->unique();
            $table->text('connection');
            $table->text('queue');
            $table->longText('payload');
            $table->longText('exception');
            $table->timestamp('failed_at')->useCurrent();
        });
    }
}
