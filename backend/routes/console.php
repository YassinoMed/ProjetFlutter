<?php

use App\Jobs\PurgeExpiredData;
use App\Jobs\SendAppointmentReminders;
use App\Jobs\SendTeleconsultationReminders;
use Illuminate\Support\Facades\Schedule;

// ── Appointment Reminders (every 15 min) ──────────────────
Schedule::job(new SendAppointmentReminders)->everyFifteenMinutes();
Schedule::job(new SendTeleconsultationReminders)->everyFifteenMinutes();

// ── RGPD Data Minimization (daily at 3 AM) ────────────────
Schedule::job(new PurgeExpiredData)->dailyAt('03:00');
