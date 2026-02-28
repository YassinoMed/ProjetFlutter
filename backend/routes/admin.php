<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Admin Panel Routes
|--------------------------------------------------------------------------
*/

// Authentication
Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
Route::post('/login', [AuthController::class, 'login'])->name('login.post');

// Protected Admin Routes
Route::middleware(['admin'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
    
    // 1. Dashboard principal
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    
    // 2. Gestion des utilisateurs (Patients & Médecins)
    // Route::get('/users', ...)->name('users.index');
    
    // 3. Gestion des rendez-vous
    // Route::get('/appointments', ...)->name('appointments.index');
    
    // 4. Supervision du Chat
    // Route::get('/chat-monitor', ...)->name('chat.index');
    
    // 5. Historique médical & RGPD
    // Route::get('/medical-records', ...)->name('records.index');
    
    // 6. Gestion des notifications
    // Route::get('/notifications', ...)->name('notifications.index');
    
    // 7. Statistiques & Rapports
    // Route::get('/reports', ...)->name('reports.index');
    
    // 8. Paramètres système
    // Route::get('/settings', ...)->name('settings.index');
});
