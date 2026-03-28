<?php

namespace App\Providers;

use App\Enums\UserRole;
use App\Models\Appointment;
use App\Models\CallSession;
use App\Models\Conversation;
use App\Models\DoctorSecretaryDelegation;
use App\Models\Document;
use App\Models\Message;
use App\Models\Teleconsultation;
use App\Policies\AppointmentPolicy;
use App\Policies\CallSessionPolicy;
use App\Policies\ConversationPolicy;
use App\Policies\DoctorSecretaryDelegationPolicy;
use App\Policies\DocumentPolicy;
use App\Policies\MessagePolicy;
use App\Policies\TeleconsultationPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        Appointment::class => AppointmentPolicy::class,
        Conversation::class => ConversationPolicy::class,
        Message::class => MessagePolicy::class,
        CallSession::class => CallSessionPolicy::class,
        DoctorSecretaryDelegation::class => DoctorSecretaryDelegationPolicy::class,
        Document::class => DocumentPolicy::class,
        Teleconsultation::class => TeleconsultationPolicy::class,
    ];

    public function boot(): void
    {
        $this->registerPolicies();

        Gate::define('is-admin', fn ($user) => $user?->role === UserRole::ADMIN);
        Gate::define('is-doctor', fn ($user) => $user?->role === UserRole::DOCTOR);
        Gate::define('is-patient', fn ($user) => $user?->role === UserRole::PATIENT);
    }
}
