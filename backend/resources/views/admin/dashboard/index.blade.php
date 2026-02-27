@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex justify-between items-center">
    <div>
        <h1 class="text-3xl font-bold text-base-content">
            Tableau de Bord Global
        </h1>
        <p class="text-sm text-base-content/70 mt-1">
            Supervision Temps Réel — MediConnect Pro
        </p>
    </div>
    
    <div class="flex gap-2">
        <button class="btn btn-outline btn-primary btn-sm">
            <span class="material-symbols-rounded text-sm">download</span>
            Export CSV
        </button>
        <button class="btn btn-primary btn-sm">
            <span class="material-symbols-rounded text-sm">add</span>
            Action Rapide
        </button>
    </div>
</div>

<!-- Dashboard Stats Livewire Component -->
<livewire:admin.dashboard-stats />

@endsection
