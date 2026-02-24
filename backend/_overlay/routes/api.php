<?php

use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FcmTokenController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:auth-register');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:auth-login');
    Route::post('/refresh', [AuthController::class, 'refresh'])->middleware('throttle:auth-refresh');

    Route::middleware('auth:api')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
    });
});

Route::middleware('auth:api')->group(function (): void {
    Route::get('/appointments', [AppointmentController::class, 'index']);
    Route::post('/appointments', [AppointmentController::class, 'store']);
    Route::get('/appointments/{appointmentId}', [AppointmentController::class, 'show']);
    Route::post('/appointments/{appointmentId}/cancel', [AppointmentController::class, 'cancel']);
    Route::post('/appointments/{appointmentId}/confirm', [AppointmentController::class, 'confirm']);

    Route::post('/fcm/tokens', [FcmTokenController::class, 'upsert']);
    Route::delete('/fcm/tokens', [FcmTokenController::class, 'destroy']);
    Route::post('/fcm/tokens/heartbeat', [FcmTokenController::class, 'heartbeat']);
});
