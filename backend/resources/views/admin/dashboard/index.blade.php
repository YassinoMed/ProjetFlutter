@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">
            Tableau de Bord Global
        </h1>
        <p class="text-sm text-base-content/70 mt-1">
            Supervision Temps Réel — MediConnect Pro
        </p>
    </div>

    <div class="flex gap-2">
        <a href="{{ route('admin.export.users') }}" class="btn btn-outline btn-primary btn-sm">
            <span class="material-symbols-rounded text-sm">download</span>
            Export CSV
        </a>
        <a href="{{ route('admin.doctors.index', ['status' => 'pending']) }}" class="btn btn-primary btn-sm">
            <span class="material-symbols-rounded text-sm">pending_actions</span>
            Approbations
        </a>
    </div>
</div>

<!-- Dashboard Stats Livewire Component -->
<livewire:admin.dashboard-stats />

<!-- Quick Actions Grid -->
<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-8">
    <a href="{{ route('admin.users.index') }}" class="card bg-base-100 shadow-sm border border-base-200 hover:shadow-lg transition-shadow cursor-pointer">
        <div class="card-body p-4 text-center">
            <span class="material-symbols-rounded text-3xl text-primary mb-2">manage_accounts</span>
            <span class="font-bold text-sm">Utilisateurs</span>
        </div>
    </a>
    <a href="{{ route('admin.appointments.index') }}" class="card bg-base-100 shadow-sm border border-base-200 hover:shadow-lg transition-shadow cursor-pointer">
        <div class="card-body p-4 text-center">
            <span class="material-symbols-rounded text-3xl text-accent mb-2">event</span>
            <span class="font-bold text-sm">Rendez-vous</span>
        </div>
    </a>
    <a href="{{ route('admin.chat.index') }}" class="card bg-base-100 shadow-sm border border-base-200 hover:shadow-lg transition-shadow cursor-pointer">
        <div class="card-body p-4 text-center">
            <span class="material-symbols-rounded text-3xl text-info mb-2">forum</span>
            <span class="font-bold text-sm">Messages E2EE</span>
        </div>
    </a>
    <a href="{{ route('admin.reports.index') }}" class="card bg-base-100 shadow-sm border border-base-200 hover:shadow-lg transition-shadow cursor-pointer">
        <div class="card-body p-4 text-center">
            <span class="material-symbols-rounded text-3xl text-secondary mb-2">monitoring</span>
            <span class="font-bold text-sm">Rapports</span>
        </div>
    </a>
</div>
@endsection
