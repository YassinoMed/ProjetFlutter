@extends('admin.layouts.app')

@section('page-title', 'Tableau de bord')

@section('content')
<section class="page-card mb-8 overflow-hidden border-none bg-[linear-gradient(135deg,rgba(11,99,206,0.96),rgba(0,78,153,0.92),rgba(8,21,47,0.96))] px-7 py-7 text-white shadow-[0_40px_80px_-42px_rgba(0,78,153,0.85)] sm:px-9 sm:py-9">
    <div class="grid gap-8 lg:grid-cols-[1.25fr_0.75fr]">
        <div>
            <div class="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/10 px-4 py-2 text-xs font-bold uppercase tracking-[0.18em] text-blue-100">
                <i class="ti ti-activity-heartbeat"></i>
                Supervision temps reel
            </div>
            <h1 class="mt-5 max-w-3xl text-4xl font-black tracking-[-0.05em] sm:text-5xl">
                Vue centrale des operations critiques et du pilotage medical.
            </h1>
            <p class="mt-4 max-w-2xl text-sm leading-7 text-blue-100/80 sm:text-base">
                Surveillez les inscriptions, les rendez-vous, la messagerie securisee et les signaux d'usage depuis une console unifiee, plus lisible et plus rapide a exploiter.
            </p>

            <div class="mt-7 flex flex-wrap gap-3">
                <a href="{{ route('admin.export.users') }}" class="btn border-white/15 bg-white/10 text-white hover:border-white/25 hover:bg-white/16">
                    <i class="ti ti-download text-lg"></i>
                    Export CSV
                </a>
                <a href="{{ route('admin.doctors.index', ['status' => 'pending']) }}" class="btn bg-white text-slate-950 hover:bg-slate-100">
                    <i class="ti ti-user-check text-lg text-blue-600"></i>
                    Traiter les approbations
                </a>
            </div>
        </div>

        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
            <div class="rounded-[1.6rem] border border-white/10 bg-white/10 p-5 backdrop-blur">
                <div class="text-xs font-bold uppercase tracking-[0.18em] text-blue-100/70">Priorite</div>
                <div class="mt-2 text-xl font-extrabold">Validation des medecins</div>
                <p class="mt-2 text-sm leading-6 text-blue-100/76">
                    Verifiez rapidement les comptes en attente et reduisez les delais d'activation.
                </p>
            </div>
            <div class="rounded-[1.6rem] border border-white/10 bg-white/10 p-5 backdrop-blur">
                <div class="text-xs font-bold uppercase tracking-[0.18em] text-emerald-100/70">Statut plateforme</div>
                <div class="mt-2 flex items-center gap-2 text-xl font-extrabold">
                    <span class="inline-block h-2.5 w-2.5 rounded-full bg-emerald-300"></span>
                    Systeme operationnel
                </div>
                <p class="mt-2 text-sm leading-6 text-blue-100/76">
                    Console disponible pour l'administration, les audits et les actions de moderation.
                </p>
            </div>
        </div>
    </div>
</section>

<livewire:admin.dashboard-stats />

<section class="mt-10">
    <div class="mb-4 flex items-end justify-between gap-4">
        <div>
            <p class="text-xs font-bold uppercase tracking-[0.22em] text-slate-400">Acces rapides</p>
            <h2 class="mt-2 text-2xl font-extrabold tracking-tight text-slate-900">Actions frequentes</h2>
        </div>
    </div>

    <div class="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <a href="{{ route('admin.users.index') }}" class="metric-card card-lift p-6 text-slate-900">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Identites</div>
                    <div class="mt-2 text-xl font-extrabold">Utilisateurs</div>
                    <p class="mt-2 text-sm leading-6 text-slate-500">Patients, medecins, admins et profils a surveiller.</p>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.25rem] bg-blue-50 text-blue-600">
                    <i class="ti ti-users-group text-[1.7rem]"></i>
                </div>
            </div>
        </a>

        <a href="{{ route('admin.appointments.index') }}" class="metric-card card-lift p-6 text-slate-900">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Planning</div>
                    <div class="mt-2 text-xl font-extrabold">Rendez-vous</div>
                    <p class="mt-2 text-sm leading-6 text-slate-500">Suivi des creneaux, litiges et annulations a traiter.</p>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.25rem] bg-emerald-50 text-emerald-600">
                    <i class="ti ti-calendar-event text-[1.7rem]"></i>
                </div>
            </div>
        </a>

        <a href="{{ route('admin.chat.index') }}" class="metric-card card-lift p-6 text-slate-900">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Communication</div>
                    <div class="mt-2 text-xl font-extrabold">Messagerie E2EE</div>
                    <p class="mt-2 text-sm leading-6 text-slate-500">Signalements, supervision conversationnelle et events temps reel.</p>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.25rem] bg-sky-50 text-sky-600">
                    <i class="ti ti-messages text-[1.7rem]"></i>
                </div>
            </div>
        </a>

        <a href="{{ route('admin.reports.index') }}" class="metric-card card-lift p-6 text-slate-900">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Analyse</div>
                    <div class="mt-2 text-xl font-extrabold">Rapports</div>
                    <p class="mt-2 text-sm leading-6 text-slate-500">Indicateurs d'activite, synthese metier et aide au pilotage.</p>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.25rem] bg-violet-50 text-violet-600">
                    <i class="ti ti-chart-bar text-[1.7rem]"></i>
                </div>
            </div>
        </a>
    </div>
</section>
@endsection
