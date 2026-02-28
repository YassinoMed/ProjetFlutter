@extends('admin.layouts.app')

@section('content')
<div class="mb-6">
    <a href="{{ route('admin.appointments.index') }}" class="btn btn-ghost btn-sm gap-1 mb-4">
        <span class="material-symbols-rounded text-sm">arrow_back</span>
        Retour aux rendez-vous
    </a>
    <h1 class="text-3xl font-bold text-base-content">Détails du Rendez-vous</h1>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Main Appointment Card -->
    <div class="card bg-base-100 shadow-sm border border-base-200 lg:col-span-2">
        <div class="card-body">
            <div class="flex items-center justify-between mb-4">
                <h2 class="card-title text-lg font-bold">
                    <span class="material-symbols-rounded text-primary">event</span>
                    Informations du Rendez-vous
                </h2>
                @switch($appointment->status?->value ?? $appointment->status)
                    @case('DRAFT')
                        <span class="badge badge-ghost">Brouillon</span>
                        @break
                    @case('REQUESTED')
                        <span class="badge badge-warning">En Attente</span>
                        @break
                    @case('CONFIRMED')
                        <span class="badge badge-success">Confirmé</span>
                        @break
                    @case('COMPLETED')
                        <span class="badge badge-info">Complété</span>
                        @break
                    @case('CANCELLED')
                        <span class="badge badge-error">Annulé</span>
                        @break
                @endswitch
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Patient</label>
                    <p class="text-lg font-semibold">
                        {{ e($appointment->patient?->first_name ?? '—') }} {{ e($appointment->patient?->last_name ?? '') }}
                    </p>
                    <p class="text-sm text-gray-400">{{ e($appointment->patient?->email ?? '') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Médecin</label>
                    <p class="text-lg font-semibold">
                        Dr. {{ e($appointment->doctor?->first_name ?? '—') }} {{ e($appointment->doctor?->last_name ?? '') }}
                    </p>
                    <p class="text-sm text-gray-400">{{ e($appointment->doctor?->email ?? '') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Début</label>
                    <p class="text-lg">{{ $appointment->starts_at_utc?->format('d/m/Y à H:i') ?? '—' }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Fin</label>
                    <p class="text-lg">{{ $appointment->ends_at_utc?->format('d/m/Y à H:i') ?? '—' }}</p>
                </div>
            </div>

            @if($appointment->cancel_reason)
                <div class="mt-4 p-3 bg-error/10 rounded-lg border border-error/20">
                    <label class="text-xs font-bold text-error uppercase tracking-wider">Raison d'annulation</label>
                    <p class="text-sm mt-1">{{ e($appointment->cancel_reason) }}</p>
                </div>
            @endif

            <div class="mt-4">
                <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Identifiant</label>
                <p class="font-mono text-sm bg-base-200 p-2 rounded mt-1">{{ $appointment->id }}</p>
            </div>
        </div>
    </div>

    <!-- Timeline Card -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h3 class="card-title text-md font-bold mb-4">
                <span class="material-symbols-rounded text-primary">timeline</span>
                Historique
            </h3>
            <ul class="timeline timeline-vertical timeline-compact">
                <li>
                    <div class="timeline-start text-xs text-gray-400">{{ $appointment->created_at?->format('d/m H:i') }}</div>
                    <div class="timeline-middle">
                        <span class="material-symbols-rounded text-xs text-primary">circle</span>
                    </div>
                    <div class="timeline-end text-sm font-medium">Créé</div>
                    <hr />
                </li>
                @if($appointment->events && $appointment->events->count())
                    @foreach($appointment->events as $event)
                        <li>
                            <hr />
                            <div class="timeline-start text-xs text-gray-400">{{ $event->created_at?->format('d/m H:i') }}</div>
                            <div class="timeline-middle">
                                <span class="material-symbols-rounded text-xs text-secondary">circle</span>
                            </div>
                            <div class="timeline-end text-sm">{{ e($event->type ?? 'Événement') }}</div>
                            <hr />
                        </li>
                    @endforeach
                @endif
            </ul>
        </div>
    </div>
</div>
@endsection
