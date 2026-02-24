<?php

namespace App\Providers;

use App\Enums\UserRole;
use App\Models\Appointment;
use App\Policies\AppointmentPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        Appointment::class => AppointmentPolicy::class,
    ];

    public function boot(): void
    {
        $this->registerPolicies();

        Gate::define('is-admin', fn ($user) => $user?->role === UserRole::ADMIN);
        Gate::define('is-doctor', fn ($user) => $user?->role === UserRole::DOCTOR);
        Gate::define('is-patient', fn ($user) => $user?->role === UserRole::PATIENT);
    }
}
