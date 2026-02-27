<?php

use App\Jobs\PurgeExpiredData;
use App\Jobs\SendAppointmentReminders;
use Illuminate\Support\Facades\Schedule;

// ── Appointment Reminders (every 15 min) ──────────────────
Schedule::job(new SendAppointmentReminders)->everyFifteenMinutes();

// ── RGPD Data Minimization (daily at 3 AM) ────────────────
Schedule::job(new PurgeExpiredData)->dailyAt('03:00');
