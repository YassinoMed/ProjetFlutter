@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Gestion des Rendez-vous</h1>
        <p class="text-sm text-base-content/70 mt-1">Supervision des créneaux et litiges</p>
    </div>
</div>

<!-- Stats Cards -->
<div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">Aujourd'hui</div>
            <div class="text-2xl font-bold text-primary mt-1">{{ $stats['today'] }}</div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">En Attente</div>
            <div class="text-2xl font-bold text-warning mt-1">{{ $stats['pending'] }}</div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">Confirmés</div>
            <div class="text-2xl font-bold text-success mt-1">{{ $stats['confirmed'] }}</div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">Annulés</div>
            <div class="text-2xl font-bold text-error mt-1">{{ $stats['cancelled'] }}</div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.appointments.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher un patient ou médecin..." />
            </div>
            <select name="status" class="select select-bordered">
                <option value="">Tous les statuts</option>
                <option value="REQUESTED" {{ request('status') == 'REQUESTED' ? 'selected' : '' }}>En Attente</option>
                <option value="CONFIRMED" {{ request('status') == 'CONFIRMED' ? 'selected' : '' }}>Confirmé</option>
                <option value="COMPLETED" {{ request('status') == 'COMPLETED' ? 'selected' : '' }}>Complété</option>
                <option value="CANCELLED" {{ request('status') == 'CANCELLED' ? 'selected' : '' }}>Annulé</option>
            </select>
            <input type="date" name="from" value="{{ request('from') }}" class="input input-bordered" />
            <input type="date" name="to" value="{{ request('to') }}" class="input input-bordered" />
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">filter_list</span>
                Filtrer
            </button>
            @if(request()->hasAny(['search', 'status', 'from', 'to']))
                <a href="{{ route('admin.appointments.index') }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Appointments Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Patient</th>
                        <th class="font-bold">Médecin</th>
                        <th class="font-bold">Date & Heure</th>
                        <th class="font-bold">Statut</th>
                        <th class="font-bold text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($appointments as $appointment)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-info">person</span>
                                    <span class="font-medium text-sm">
                                        {{ e($appointment->patient?->first_name ?? '—') }}
                                        {{ e($appointment->patient?->last_name ?? '') }}
                                    </span>
                                </div>
                            </td>
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-success">stethoscope</span>
                                    <span class="font-medium text-sm">
                                        Dr. {{ e($appointment->doctor?->first_name ?? '—') }}
                                        {{ e($appointment->doctor?->last_name ?? '') }}
                                    </span>
                                </div>
                            </td>
                            <td class="text-sm">
                                <div class="font-medium">{{ $appointment->starts_at_utc?->format('d/m/Y') }}</div>
                                <div class="text-xs text-gray-400">
                                    {{ $appointment->starts_at_utc?->format('H:i') }} — {{ $appointment->ends_at_utc?->format('H:i') }}
                                </div>
                            </td>
                            <td>
                                @switch($appointment->status?->value ?? $appointment->status)
                                    @case('DRAFT')
                                        <span class="badge badge-ghost badge-sm">Brouillon</span>
                                        @break
                                    @case('REQUESTED')
                                        <span class="badge badge-warning badge-sm">En Attente</span>
                                        @break
                                    @case('CONFIRMED')
                                        <span class="badge badge-success badge-sm">Confirmé</span>
                                        @break
                                    @case('COMPLETED')
                                        <span class="badge badge-info badge-sm">Complété</span>
                                        @break
                                    @case('CANCELLED')
                                        <span class="badge badge-error badge-sm">Annulé</span>
                                        @break
                                @endswitch
                            </td>
                            <td class="text-center">
                                <div class="flex items-center justify-center gap-1">
                                    <a href="{{ route('admin.appointments.show', $appointment->id) }}" class="btn btn-ghost btn-sm btn-circle" title="Détails">
                                        <span class="material-symbols-rounded text-sm">visibility</span>
                                    </a>

                                    @if(!in_array($appointment->status?->value ?? $appointment->status, ['CANCELLED', 'COMPLETED']))
                                        <button class="btn btn-ghost btn-sm btn-circle text-error" title="Annuler"
                                                onclick="document.getElementById('cancel-modal-{{ $appointment->id }}').showModal()">
                                            <span class="material-symbols-rounded text-sm">cancel</span>
                                        </button>

                                        <!-- Cancel Modal -->
                                        <dialog id="cancel-modal-{{ $appointment->id }}" class="modal">
                                            <div class="modal-box">
                                                <h3 class="font-bold text-lg text-error">Annuler le rendez-vous</h3>
                                                <p class="py-4 text-sm">Cette action annulera le rendez-vous de manière définitive.</p>
                                                <form method="POST" action="{{ route('admin.appointments.cancel', $appointment->id) }}">
                                                    @csrf
                                                    <div class="form-control mb-4">
                                                        <label class="label"><span class="label-text">Raison de l'annulation</span></label>
                                                        <textarea name="cancel_reason" rows="3" required
                                                                  class="textarea textarea-bordered" placeholder="Indiquez la raison..."></textarea>
                                                    </div>
                                                    <div class="modal-action">
                                                        <button type="button" class="btn btn-ghost"
                                                                onclick="document.getElementById('cancel-modal-{{ $appointment->id }}').close()">Fermer</button>
                                                        <button type="submit" class="btn btn-error">Confirmer l'annulation</button>
                                                    </div>
                                                </form>
                                            </div>
                                            <form method="dialog" class="modal-backdrop"><button>close</button></form>
                                        </dialog>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">event_busy</span>
                                Aucun rendez-vous trouvé.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($appointments->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $appointments->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
