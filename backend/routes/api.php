<?php

use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CallSessionController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\DelegationContextController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\DoctorController;
use App\Http\Controllers\Api\DoctorSecretaryController;
use App\Http\Controllers\Api\DocumentController;
use App\Http\Controllers\Api\DocumentSharingController;
use App\Http\Controllers\Api\E2eeKeyController;
use App\Http\Controllers\Api\EmergencyMedicalInfoController;
use App\Http\Controllers\Api\EncryptedAttachmentController;
use App\Http\Controllers\Api\FcmTokenController;
use App\Http\Controllers\Api\GdprExportController;
use App\Http\Controllers\Api\GeminiController;
use App\Http\Controllers\Api\MeDelegationController;
use App\Http\Controllers\Api\MedicalRecordMetadataController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\Ops\HealthController;
use App\Http\Controllers\Api\Ops\MetricsController;
use App\Http\Controllers\Api\PatientConsentController;
use App\Http\Controllers\Api\PreConsultationQuestionnaireController;
use App\Http\Controllers\Api\PresenceController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\RgpdController;
use App\Http\Controllers\Api\ScheduleController;
use App\Http\Controllers\Api\SecretaryInvitationController;
use App\Http\Controllers\Api\TeleconsultationController;
use App\Http\Controllers\Api\WaitingRoomController;
use App\Http\Controllers\Api\WebRtcController;
use App\Http\Controllers\Api\WebRtcSignalingController;
use App\Models\Tenant;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Route;

Route::get('/tenants', function () {
    return response()->json([
        'success' => true,
        'message' => 'Tenants retrieved successfully',
        'data' => Tenant::where('is_active', true)->get(['id', 'name']),
        'error' => null,
        'meta' => null,
    ]);
});

Route::prefix('ops/health')->group(function (): void {
    Route::get('/live', [HealthController::class, 'live']);
    Route::get('/ready', [HealthController::class, 'ready']);
});
Route::get('/ops/metrics', MetricsController::class);

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

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);

        // ── Biometric Device Management ──────────────────
        Route::post('/enable-biometric', [AuthController::class, 'enableBiometric']);
        Route::post('/disable-biometric', [AuthController::class, 'disableBiometric']);
        Route::get('/devices', [DeviceController::class, 'index']);
        Route::delete('/devices/{deviceId}', [DeviceController::class, 'destroy']);
    });
});

if (! app()->environment('testing')) {
    Broadcast::routes(['middleware' => ['auth:sanctum']]);
}

// ── AI Assistant via Gemini ─────────────────────────────────
// Public in local/dev so Flutter Web can use the local Laravel proxy without
// depending on the remote Sanctum token. Keep throttling enabled.
Route::post('/gemini/chat', [GeminiController::class, 'chat'])->middleware('throttle:api');
Route::post('/gemini/document', [GeminiController::class, 'document'])->middleware('throttle:api');
Route::post('/genui/stream', [GeminiController::class, 'genuiStream'])->middleware('throttle:api');

// ── A2UI catalog fallback ───────────────────────────────────
// Sert le catalogue A2UI v0.9 que le client Flutter peut récupérer si la
// référence externe `https://a2ui.org/specification/v0_9/standard_catalog.json`
// est inaccessible. Le client s'enregistre localement via MediConnectCatalog
// (lib/core/genui/mediconnect_catalog.dart, catalogId=com.mediconnect.catalog)
// — cette route reste utile pour debug + future migration multi-tenants
// du catalogue.
Route::get('/a2ui/catalog', function () {
    $path = storage_path('app/a2ui-catalog.json');
    if (! file_exists($path)) {
        return response()->json([
            'catalogId' => 'com.mediconnect.catalog',
            'version' => 'v0.9',
            'items' => [],
            'note' => 'Catalog stub. Override by placing the real JSON at storage/app/a2ui-catalog.json.',
        ], 200);
    }

    return response()->file($path, ['Content-Type' => 'application/json']);
})->middleware('throttle:api');

// ── Authenticated Routes ─────────────────────────────────────
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function (): void {

    // ── Doctors ──────────────────────────────────────────
    Route::get('/doctors/specialties', [DoctorController::class, 'specialties']);
    Route::get('/doctors', [DoctorController::class, 'index']);
    Route::get('/doctors/{doctorUserId}', [DoctorController::class, 'show']);
    Route::get('/doctors/{doctorUserId}/slots', [DoctorController::class, 'slots']);

    // ── Doctor Schedule Management (doctor-only) ─────────
    Route::prefix('schedule')->middleware('doctor.context')->group(function (): void {
        Route::get('/', [ScheduleController::class, 'index']);
        Route::post('/', [ScheduleController::class, 'upsert']);
        Route::put('/bulk', [ScheduleController::class, 'bulkUpdate']);
        Route::delete('/{scheduleId}', [ScheduleController::class, 'destroy']);
    });

    // ── Appointments ─────────────────────────────────────
    Route::middleware('doctor.context')->group(function (): void {
        Route::get('/appointments', [AppointmentController::class, 'index']);
        Route::post('/appointments', [AppointmentController::class, 'store']);
        Route::get('/appointments/{appointmentId}', [AppointmentController::class, 'show']);
        Route::post('/appointments/{appointmentId}/cancel', [AppointmentController::class, 'cancel']);
        Route::post('/appointments/{appointmentId}/confirm', [AppointmentController::class, 'confirm']);
        Route::post('/appointments/{appointmentId}/reject', [AppointmentController::class, 'reject']);

        Route::prefix('teleconsultations')->middleware('throttle:calls')->group(function (): void {
            Route::post('/', [TeleconsultationController::class, 'store']);
            Route::get('/', [TeleconsultationController::class, 'index']);
            Route::get('/{teleconsultationId}', [TeleconsultationController::class, 'show']);
            Route::post('/{teleconsultationId}/start', [TeleconsultationController::class, 'start']);
            Route::post('/{teleconsultationId}/join', [TeleconsultationController::class, 'join']);
            Route::post('/{teleconsultationId}/cancel', [TeleconsultationController::class, 'cancel']);
            Route::post('/{teleconsultationId}/end', [TeleconsultationController::class, 'end']);
            Route::post('/{teleconsultationId}/signal/offer', [TeleconsultationController::class, 'offer'])->middleware('throttle:webrtc');
            Route::post('/{teleconsultationId}/signal/answer', [TeleconsultationController::class, 'answer'])->middleware('throttle:webrtc');
            Route::post('/{teleconsultationId}/signal/ice-candidate', [TeleconsultationController::class, 'ice'])->middleware('throttle:webrtc');
            Route::get('/{teleconsultationId}/events', [TeleconsultationController::class, 'events']);
        });
    });

    // ── Doctor Secretaries ───────────────────────────────
    Route::post('/doctor/secretaries/invite', [DoctorSecretaryController::class, 'invite'])->middleware('throttle:secretaries');
    Route::get('/doctor/secretaries', [DoctorSecretaryController::class, 'index'])->middleware('throttle:secretaries');
    Route::patch('/doctor/secretaries/{delegationId}/permissions', [DoctorSecretaryController::class, 'updatePermissions'])->middleware('throttle:secretaries');
    Route::patch('/doctor/secretaries/{delegationId}/suspend', [DoctorSecretaryController::class, 'suspend'])->middleware('throttle:secretaries');
    Route::patch('/doctor/secretaries/{delegationId}/reactivate', [DoctorSecretaryController::class, 'reactivate'])->middleware('throttle:secretaries');
    Route::delete('/doctor/secretaries/{delegationId}', [DoctorSecretaryController::class, 'destroy'])->middleware('throttle:secretaries');
    Route::get('/me/delegations', [MeDelegationController::class, 'index'])->middleware('throttle:secretaries');
    Route::post('/context/switch-doctor', [DelegationContextController::class, 'switchDoctor'])->middleware('throttle:secretaries');

    // ── Chat ─────────────────────────────────────────────
    Route::get('/consultations/{appointmentId}/messages', [ChatController::class, 'index'])->middleware('throttle:chat-messages');
    Route::post('/consultations/{appointmentId}/messages', [ChatController::class, 'store'])->middleware('throttle:chat-messages');
    Route::post('/consultations/{appointmentId}/messages/{messageId}/ack', [ChatController::class, 'ack'])->middleware('throttle:chat-messages');

    // ── Secure Conversations / E2EE Messaging ───────────
    Route::get('/conversations', [ConversationController::class, 'index'])->middleware('throttle:conversations');
    Route::post('/conversations', [ConversationController::class, 'store'])->middleware('throttle:conversations');
    Route::get('/conversations/{conversationId}', [ConversationController::class, 'show'])->middleware('throttle:conversations');
    Route::get('/conversations/{conversationId}/messages', [ConversationController::class, 'messages'])->middleware('throttle:messages');
    Route::post('/conversations/{conversationId}/typing', [MessageController::class, 'typing'])->middleware('throttle:messages');
    Route::get('/presence/{conversationId}', [PresenceController::class, 'show'])->middleware('throttle:conversations');
    Route::post('/messages', [MessageController::class, 'store'])->middleware('throttle:messages');
    Route::post('/messages/{messageId}/delivered', [MessageController::class, 'delivered'])->middleware('throttle:messages');
    Route::post('/messages/{messageId}/read', [MessageController::class, 'read'])->middleware('throttle:messages');

    // ── WebRTC Signaling ─────────────────────────────────
    Route::get('/webrtc/ice-servers', [WebRtcController::class, 'iceServers'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/join', [WebRtcController::class, 'join'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/offer', [WebRtcController::class, 'offer'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/answer', [WebRtcController::class, 'answer'])->middleware('throttle:webrtc');
    Route::post('/consultations/{appointmentId}/webrtc/ice', [WebRtcController::class, 'ice'])->middleware('throttle:webrtc');

    // ── Call Sessions / WebRTC Signaling via Laravel ────
    Route::get('/calls/{callSessionId}', [CallSessionController::class, 'show'])->middleware('throttle:calls');
    Route::post('/calls/initiate', [CallSessionController::class, 'initiate'])->middleware('throttle:calls');
    Route::post('/calls/{callSessionId}/accept', [CallSessionController::class, 'accept'])->middleware('throttle:calls');
    Route::post('/calls/{callSessionId}/reject', [CallSessionController::class, 'reject'])->middleware('throttle:calls');
    Route::post('/calls/{callSessionId}/cancel', [CallSessionController::class, 'cancel'])->middleware('throttle:calls');
    Route::post('/calls/{callSessionId}/end', [CallSessionController::class, 'end'])->middleware('throttle:calls');
    Route::post('/calls/{callSessionId}/livekit-token', [CallSessionController::class, 'liveKitToken'])->middleware('throttle:calls');
    Route::post('/calls/{callSessionId}/offer', [WebRtcSignalingController::class, 'offer'])->middleware('throttle:webrtc');
    Route::post('/calls/{callSessionId}/answer', [WebRtcSignalingController::class, 'answer'])->middleware('throttle:webrtc');
    Route::post('/calls/{callSessionId}/ice-candidates', [WebRtcSignalingController::class, 'ice'])->middleware('throttle:webrtc');

    // ── FCM Tokens ───────────────────────────────────────
    Route::post('/fcm/tokens', [FcmTokenController::class, 'upsert']);
    Route::delete('/fcm/tokens', [FcmTokenController::class, 'destroy']);
    Route::post('/fcm/tokens/heartbeat', [FcmTokenController::class, 'heartbeat']);
    Route::post('/devices/register-push-token', [DeviceTokenController::class, 'register']);
    Route::post('/devices/push-token-heartbeat', [DeviceTokenController::class, 'heartbeat']);
    Route::delete('/devices/push-token', [DeviceTokenController::class, 'destroy']);

    // ── Medical Documents & AI Summaries ─────────────────
    Route::prefix('documents')->middleware('throttle:documents')->group(function (): void {
        Route::post('/upload', [DocumentController::class, 'upload']);
        Route::get('/', [DocumentController::class, 'index']);
        Route::get('/{documentId}', [DocumentController::class, 'show'])->whereUuid('documentId');
        Route::get('/{documentId}/processing', [DocumentController::class, 'processing'])->whereUuid('documentId');
        Route::get('/{documentId}/summary', [DocumentController::class, 'summary'])->whereUuid('documentId');
        Route::get('/{documentId}/entities', [DocumentController::class, 'entities'])->whereUuid('documentId');
        Route::post('/{documentId}/reanalyze', [DocumentController::class, 'reanalyze'])->whereUuid('documentId');
        Route::post('/{documentId}/ask', [DocumentController::class, 'ask'])->whereUuid('documentId');
        Route::delete('/{documentId}', [DocumentController::class, 'destroy'])->whereUuid('documentId');
    });

    // ── E2EE Key Bundles ────────────────────────────────
    Route::post('/e2ee/devices', [E2eeKeyController::class, 'upsertOwnDevice'])->middleware('throttle:conversations');
    Route::get('/e2ee/users/{userId}/bundle', [E2eeKeyController::class, 'showPeerBundle'])->middleware('throttle:conversations');

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

    // ── Pre-consultation questionnaire ───────────────────
    Route::get('/appointments/{appointment}/questionnaire', [PreConsultationQuestionnaireController::class, 'show']);
    Route::post('/appointments/{appointment}/questionnaire', [PreConsultationQuestionnaireController::class, 'store']);
    Route::put('/questionnaires/{questionnaire}', [PreConsultationQuestionnaireController::class, 'update']);
    Route::delete('/questionnaires/{questionnaire}', [PreConsultationQuestionnaireController::class, 'destroy']);

    // ── Emergency QR ─────────────────────────────────────
    Route::get('/me/emergency-info', [EmergencyMedicalInfoController::class, 'show']);
    Route::post('/me/emergency-info', [EmergencyMedicalInfoController::class, 'store']);
    Route::put('/me/emergency-info', [EmergencyMedicalInfoController::class, 'update']);
    Route::post('/me/emergency-info/enable', [EmergencyMedicalInfoController::class, 'enable']);
    Route::post('/me/emergency-info/disable', [EmergencyMedicalInfoController::class, 'disable']);

    // ── GDPR Export persistence ──────────────────────────
    Route::post('/me/gdpr-export', [GdprExportController::class, 'request'])->middleware('throttle:rgpd');
    Route::get('/me/gdpr-export/history', [GdprExportController::class, 'history'])->middleware('throttle:rgpd');
    Route::get('/me/gdpr-export/{id}/download', [GdprExportController::class, 'download'])->middleware('throttle:rgpd');

    // ── Waiting room ─────────────────────────────────────
    Route::post('/appointments/{appointment}/waiting-room/join', [WaitingRoomController::class, 'join']);
    Route::get('/doctor/waiting-room', [WaitingRoomController::class, 'doctorIndex']);
    Route::post('/waiting-room/{session}/admit', [WaitingRoomController::class, 'admit']);
    Route::post('/waiting-room/{session}/reject', [WaitingRoomController::class, 'reject']);
    Route::post('/waiting-room/{session}/cancel', [WaitingRoomController::class, 'cancel']);
    Route::post('/waiting-room/{session}/expire', [WaitingRoomController::class, 'expire']);

    // ── Granular patient consents ───────────────────────
    Route::get('/me/consents', [PatientConsentController::class, 'index']);
    Route::post('/me/consents', [PatientConsentController::class, 'store']);
    Route::put('/me/consents/{consent}', [PatientConsentController::class, 'update']);
    Route::delete('/me/consents/{consent}', [PatientConsentController::class, 'destroy']);

    Route::get('/doctors/{doctor}/shared-documents', [DocumentSharingController::class, 'sharedDocuments']);
    Route::post('/documents/{document}/share-with-doctor', [DocumentSharingController::class, 'shareWithDoctor']);
    Route::delete('/documents/{document}/revoke-doctor/{doctor}', [DocumentSharingController::class, 'revokeDoctor']);
});

Route::post('/secretary/invitations/accept', [SecretaryInvitationController::class, 'accept'])->middleware('throttle:auth-register');

// ── Public emergency QR (read-only via opaque token) ───────
Route::get('/emergency/{publicToken}', [EmergencyMedicalInfoController::class, 'publicShow'])
    ->middleware('throttle:rgpd')
    ->where('publicToken', '[A-Za-z0-9]{16,128}');
