<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'success' => true,
        'message' => 'MediConnect backend is running.',
        'data' => [
            'service' => config('app.name', 'MediConnect API'),
            'environment' => app()->environment(),
            'health' => [
                'up' => url('/up'),
                'live' => url('/api/ops/health/live'),
                'ready' => url('/api/ops/health/ready'),
            ],
        ],
        'error' => null,
        'meta' => null,
    ]);
});
