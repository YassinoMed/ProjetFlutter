<?php

use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\DoctorController;
use App\Http\Controllers\Api\EncryptedAttachmentController;
use App\Http\Controllers\Api\FcmTokenController;
use App\Http\Controllers\Api\MedicalRecordMetadataController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\RgpdController;
use App\Http\Controllers\Api\ScheduleController;
use App\Http\Controllers\Api\WebRtcController;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Route;
use App\Models\Tenant;

Route::get('/tenants', function () {
    return response()->json([
        'success' => true,
        'message' => 'Tenants retrieved successfully',
        'data' => Tenant::where('is_active', true)->get(['id', 'name']),
        'error' => null,
        'meta' => null,
    ]);
});

Route::prefix('auth')->group(function (): void {
    Route::get('/register', function () {
        return response()->json([
            'message' => 'Use POST /api/auth/register to create an account.',
            'required_fields' => ['email', 'password', 'first_name', 'last_name'],
            'optional_fields' => ['phone'],
        ]);
    });
    Route::get('/login', function () {
        return response()->json([
            'message' => 'Use POST /api/auth/login to authenticate.',
            'required_fields' => ['email', 'password'],
        ]);
    });
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:auth-register');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:auth-login');
    Route::post('/refresh', [AuthController::class, 'refresh'])->middleware('throttle:auth-refresh');

    Route::middleware('auth:api')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
    });
});

if (! app()->environment('testing')) {
    Broadcast::routes(['middleware' => ['auth:api']]);
}

// ── Public (but authenticated) Doctor Search ──────────────────
Route::middleware(['auth:api', 'throttle:api'])->group(function (): void {

    // ── Doctors ──────────────────────────────────────────
    Route::get('/doctors/specialties', [DoctorController::class, 'specialties']);
    Route::get('/doctors', [DoctorController::class, 'index']);
    Route::get('/doctors/{doctorUserId}', [DoctorController::class, 'show']);
    Route::get('/doctors/{doctorUserId}/slots', [DoctorController::class, 'slots']);

    // ── Doctor Schedule Management (doctor-only) ─────────
    Route::prefix('schedule')->group(function (): void {
        Route::get('/', [ScheduleController::class, 'index']);
        Route::post('/', [ScheduleController::class, 'upsert']);
        Route::put('/bulk', [ScheduleController::class, 'bulkUpdate']);
        Route::delete('/{scheduleId}', [ScheduleController::class, 'destroy']);
    });

    // ── Appointments ─────────────────────────────────────
    Route::get('/appointments', [AppointmentController::class, 'index']);
    Route::post('/appointments', [AppointmentController::class, 'store']);
    Route::get('/appointments/{appointmentId}', [AppointmentController::class, 'show']);
    Route::post('/appointments/{appointmentId}/cancel', [AppointmentController::class, 'cancel']);
    Route::post('/appointments/{appointmentId}/confirm', [AppointmentController::class, 'confirm']);

    // ── Chat ─────────────────────────────────────────────
    Route::get('/consultations/{appointmentId}/messages', [ChatController::class, 'index'])->middleware('throttle:chat-messages');
    Route::post('/consultations/{appointmentId}/messages', [ChatController::class, 'store'])->middleware('throttle:chat-messages');
    Route::post('/consultations/{appointmentId}/messages/{messageId}/ack', [ChatController::class, 'ack'])->middleware('throttle:chat-messages');

    // ── WebRTC Signaling ─────────────────────────────────
    Route::post('/consultations/{appointmentId}/webrtc/join', [WebRtcController::class, 'join'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/offer', [WebRtcController::class, 'offer'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/answer', [WebRtcController::class, 'answer'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/ice', [WebRtcController::class, 'ice'])->middleware('throttle:webrtc');

    // ── FCM Tokens ───────────────────────────────────────
    Route::post('/fcm/tokens', [FcmTokenController::class, 'upsert']);
    Route::delete('/fcm/tokens', [FcmTokenController::class, 'destroy']);
    Route::post('/fcm/tokens/heartbeat', [FcmTokenController::class, 'heartbeat']);

    // ── Profile ──────────────────────────────────────────
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::put('/profile/password', [ProfileController::class, 'updatePassword']);

    // ── Medical Records ──────────────────────────────────
    Route::get('/medical-records', [MedicalRecordMetadataController::class, 'index']);
    Route::post('/medical-records', [MedicalRecordMetadataController::class, 'store']);
    Route::get('/medical-records/{recordId}', [MedicalRecordMetadataController::class, 'show']);

    // ── E2EE Encrypted Attachments ───────────────────────
    Route::prefix('attachments')->group(function (): void {
        Route::post('/upload', [EncryptedAttachmentController::class, 'upload']);
        Route::get('/{attachmentId}', [EncryptedAttachmentController::class, 'show']);
        Route::get('/{attachmentId}/download', [EncryptedAttachmentController::class, 'download']);
        Route::delete('/{attachmentId}', [EncryptedAttachmentController::class, 'destroy']);
    });

    // ── RGPD ─────────────────────────────────────────────
    Route::get('/rgpd/export', [RgpdController::class, 'export'])->middleware('throttle:rgpd');
    Route::post('/rgpd/consent', [RgpdController::class, 'consent'])->middleware('throttle:rgpd');
    Route::delete('/rgpd/forget', [RgpdController::class, 'forget'])->middleware('throttle:rgpd');
});
