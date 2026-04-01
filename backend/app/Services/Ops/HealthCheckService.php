<?php

namespace App\Services\Ops;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthCheckService
{
    public function live(): array
    {
        return [
            'status' => 'ok',
            'service' => config('app.name', 'mediconnect-api'),
            'timestamp_utc' => now('UTC')->toISOString(),
        ];
    }

    public function ready(): array
    {
        $checks = [
            'database' => $this->databaseCheck(),
            'redis' => $this->redisCheck(),
            'storage' => $this->storageCheck(),
        ];

        $criticalChecks = collect($checks)
            ->filter(fn (array $check): bool => $check['critical'] === true);

        $ready = $criticalChecks->every(fn (array $check): bool => $check['status'] === 'ok');

        return [
            'status' => $ready ? 'ready' : 'not_ready',
            'service' => config('app.name', 'mediconnect-api'),
            'timestamp_utc' => now('UTC')->toISOString(),
            'checks' => $checks,
        ];
    }

    private function databaseCheck(): array
    {
        try {
            DB::connection()->select('select 1');

            return [
                'status' => 'ok',
                'critical' => true,
                'connection' => config('database.default'),
            ];
        } catch (\Throwable $exception) {
            return [
                'status' => 'failed',
                'critical' => true,
                'connection' => config('database.default'),
                'reason' => $this->sanitize($exception->getMessage()),
            ];
        }
    }

    private function redisCheck(): array
    {
        try {
            $response = Redis::connection()->ping();
            $healthy = $response === true || str_contains(strtolower((string) $response), 'pong');

            return [
                'status' => $healthy ? 'ok' : 'failed',
                'critical' => true,
                'connection' => env('REDIS_QUEUE_CONNECTION', 'default'),
            ];
        } catch (\Throwable $exception) {
            return [
                'status' => 'failed',
                'critical' => true,
                'connection' => env('REDIS_QUEUE_CONNECTION', 'default'),
                'reason' => $this->sanitize($exception->getMessage()),
            ];
        }
    }

    private function storageCheck(): array
    {
        $disk = (string) config('documents.disk', config('filesystems.default'));
        $config = (array) config("filesystems.disks.{$disk}", []);
        $driver = (string) ($config['driver'] ?? 'unknown');

        try {
            if ($driver === 'local') {
                $root = (string) ($config['root'] ?? storage_path('app/private'));

                return [
                    'status' => is_dir($root) ? 'ok' : 'failed',
                    'critical' => false,
                    'disk' => $disk,
                    'driver' => $driver,
                ];
            }

            $hasRemoteConfig = filled($config['bucket'] ?? null);

            return [
                'status' => $hasRemoteConfig ? 'ok' : 'failed',
                'critical' => false,
                'disk' => $disk,
                'driver' => $driver,
            ];
        } catch (\Throwable $exception) {
            return [
                'status' => 'failed',
                'critical' => false,
                'disk' => $disk,
                'driver' => $driver,
                'reason' => $this->sanitize($exception->getMessage()),
            ];
        }
    }

    private function sanitize(string $message): string
    {
        return str($message)->limit(160)->toString();
    }
}
