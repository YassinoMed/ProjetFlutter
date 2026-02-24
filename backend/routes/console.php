<?php

use App\Jobs\PurgeExpiredDataJob;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

// ── RGPD Data Minimization: purge expired data daily at 3 AM UTC ──
Schedule::job(new PurgeExpiredDataJob)->dailyAt('03:00')->withoutOverlapping();
