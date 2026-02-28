<?php

use App\Http\Controllers\Admin\ActivityLogController;
use App\Http\Controllers\Admin\AppointmentController;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\ChatMonitorController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\DoctorApprovalController;
use App\Http\Controllers\Admin\ExportController;
use App\Http\Controllers\Admin\MedicalRecordController;
use App\Http\Controllers\Admin\NotificationController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\ReportController;
use App\Http\Controllers\Admin\RgpdController;
use App\Http\Controllers\Admin\SettingsController;
use App\Http\Controllers\Admin\UserController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Admin Panel Routes
|--------------------------------------------------------------------------
*/

// Authentication
Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
Route::post('/login', [AuthController::class, 'login'])->name('login.post')
    ->middleware('throttle:5,1');

// Protected Admin Routes
Route::middleware(['admin'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    // ── 1. Dashboard ──────────────────────────────────────────
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

    // ── 2. Gestion des utilisateurs ───────────────────────────
    Route::get('/users', [UserController::class, 'index'])->name('users.index');
    Route::get('/users/{userId}', [UserController::class, 'show'])->name('users.show');
    Route::post('/users/{userId}/toggle-status', [UserController::class, 'toggleStatus'])->name('users.toggle-status');

    // ── 3. Approbation Médecins ───────────────────────────────
    Route::get('/doctors', [DoctorApprovalController::class, 'index'])->name('doctors.index');
    Route::get('/doctors/{doctorUserId}', [DoctorApprovalController::class, 'show'])->name('doctors.show');
    Route::post('/doctors/{doctorUserId}/approve', [DoctorApprovalController::class, 'approve'])->name('doctors.approve');
    Route::post('/doctors/{doctorUserId}/reject', [DoctorApprovalController::class, 'reject'])->name('doctors.reject');

    // ── 4. Gestion des rendez-vous ────────────────────────────
    Route::get('/appointments', [AppointmentController::class, 'index'])->name('appointments.index');
    Route::get('/appointments/{appointmentId}', [AppointmentController::class, 'show'])->name('appointments.show');
    Route::post('/appointments/{appointmentId}/cancel', [AppointmentController::class, 'forceCancel'])->name('appointments.cancel');

    // ── 5. Supervision du Chat ────────────────────────────────
    Route::get('/chat-monitor', [ChatMonitorController::class, 'index'])->name('chat.index');

    // ── 6. Dossiers Médicaux (métadonnées E2EE) ───────────────
    Route::get('/medical-records', [MedicalRecordController::class, 'index'])->name('medical-records.index');

    // ── 7. RGPD / Droit à l'Oubli ─────────────────────────────
    Route::get('/rgpd', [RgpdController::class, 'index'])->name('rgpd.index');
    Route::post('/rgpd/anonymize/{userId}', [RgpdController::class, 'anonymize'])->name('rgpd.anonymize');

    // ── 8. Push Notifications ─────────────────────────────────
    Route::get('/notifications', [NotificationController::class, 'index'])->name('notifications.index');

    // ── 9. Statistiques & Rapports ────────────────────────────
    Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');

    // ── 10. Journal d'Activité (Audit Trail) ──────────────────
    Route::get('/activity-log', [ActivityLogController::class, 'index'])->name('activity-log.index');

    // ── 11. Export CSV ────────────────────────────────────────
    Route::get('/export/users', [ExportController::class, 'users'])->name('export.users');
    Route::get('/export/appointments', [ExportController::class, 'appointments'])->name('export.appointments');

    // ── 12. Profil Admin ──────────────────────────────────────
    Route::get('/profile', [ProfileController::class, 'index'])->name('profile.index');
    Route::put('/profile', [ProfileController::class, 'updateProfile'])->name('profile.update');
    Route::put('/profile/password', [ProfileController::class, 'updatePassword'])->name('profile.password');

    // ── 13. Paramètres système ────────────────────────────────
    Route::get('/settings', [SettingsController::class, 'index'])->name('settings.index');
    Route::post('/settings/clear-cache', [SettingsController::class, 'clearCache'])->name('settings.clear-cache');
});
