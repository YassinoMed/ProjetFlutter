<?php

namespace App\Providers;

use App\Events\AppointmentStatusChanged;
use App\Listeners\SendAppointmentNotificationsListener;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        AppointmentStatusChanged::class => [
            SendAppointmentNotificationsListener::class,
        ],
    ];
}
