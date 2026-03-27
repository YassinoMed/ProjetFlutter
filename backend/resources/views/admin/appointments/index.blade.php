@extends('admin.layouts.app')

@section('page-title', 'Gestion des rendez-vous')

@section('content')
<div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
    <div>
        <p class="text-xs font-bold uppercase tracking-[0.22em] text-slate-400">Orchestration planning</p>
        <h1 class="mt-2 text-3xl font-black tracking-tight text-slate-950">Rendez-vous, litiges et creneaux medicaux</h1>
        <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-500">
            Surveillez les demandes, annulations et confirmations avec un tableau plus lisible pour les operations quotidiennes.
        </p>
    </div>
</div>

<section class="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
    <div class="metric-card p-5 text-blue-700">
        <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Aujourd'hui</div>
        <div class="mt-3 flex items-end justify-between gap-3">
            <div class="text-3xl font-black text-slate-900">{{ $stats['today'] }}</div>
            <div class="flex h-12 w-12 items-center justify-center rounded-[1.1rem] bg-blue-50">
                <i class="ti ti-calendar-time text-[1.5rem]"></i>
            </div>
        </div>
    </div>
    <div class="metric-card p-5 text-amber-600">
        <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">En attente</div>
        <div class="mt-3 flex items-end justify-between gap-3">
            <div class="text-3xl font-black text-slate-900">{{ $stats['pending'] }}</div>
            <div class="flex h-12 w-12 items-center justify-center rounded-[1.1rem] bg-amber-50">
                <i class="ti ti-hourglass-high text-[1.5rem]"></i>
            </div>
        </div>
    </div>
    <div class="metric-card p-5 text-emerald-600">
        <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Confirmes</div>
        <div class="mt-3 flex items-end justify-between gap-3">
            <div class="text-3xl font-black text-slate-900">{{ $stats['confirmed'] }}</div>
            <div class="flex h-12 w-12 items-center justify-center rounded-[1.1rem] bg-emerald-50">
                <i class="ti ti-circle-check text-[1.5rem]"></i>
            </div>
        </div>
    </div>
    <div class="metric-card p-5 text-rose-600">
        <div class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Annules</div>
        <div class="mt-3 flex items-end justify-between gap-3">
            <div class="text-3xl font-black text-slate-900">{{ $stats['cancelled'] }}</div>
            <div class="flex h-12 w-12 items-center justify-center rounded-[1.1rem] bg-rose-50">
                <i class="ti ti-calendar-off text-[1.5rem]"></i>
            </div>
        </div>
    </div>
</section>

<section class="filter-shell mb-6">
    <div class="p-5 sm:p-6">
        <form method="GET" action="{{ route('admin.appointments.index') }}" class="grid gap-3 xl:grid-cols-[minmax(0,1fr)_220px_170px_170px_auto_auto]">
            <div class="relative">
                <i class="ti ti-search absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"></i>
                <input
                    type="text"
                    name="search"
                    value="{{ request('search') }}"
                    class="input h-12 w-full pl-11"
                    placeholder="Patient, medecin ou terme de recherche..."
                />
            </div>

            <select name="status" class="select h-12 w-full">
                <option value="">Tous les statuts</option>
                <option value="REQUESTED" {{ request('status') == 'REQUESTED' ? 'selected' : '' }}>En attente</option>
                <option value="CONFIRMED" {{ request('status') == 'CONFIRMED' ? 'selected' : '' }}>Confirmes</option>
                <option value="COMPLETED" {{ request('status') == 'COMPLETED' ? 'selected' : '' }}>Completes</option>
                <option value="CANCELLED" {{ request('status') == 'CANCELLED' ? 'selected' : '' }}>Annules</option>
            </select>

            <input type="date" name="from" value="{{ request('from') }}" class="input h-12 w-full" />
            <input type="date" name="to" value="{{ request('to') }}" class="input h-12 w-full" />

            <button type="submit" class="btn btn-primary h-12">
                <i class="ti ti-filter text-lg"></i>
                Filtrer
            </button>

            @if(request()->hasAny(['search', 'status', 'from', 'to']))
                <a href="{{ route('admin.appointments.index') }}" class="btn btn-ghost h-12">
                    <i class="ti ti-rotate-2 text-lg"></i>
                    Reinitialiser
                </a>
            @endif
        </form>
    </div>
</section>

<section class="table-shell">
    <div class="border-b border-slate-200/70 px-5 py-4 sm:px-6">
        <h2 class="text-lg font-extrabold text-slate-900">Planning supervise</h2>
        <p class="text-sm text-slate-500">Liste des rendez-vous avec acces aux details et annulations admin.</p>
    </div>

    <div class="overflow-x-auto">
        <table class="table table-zebra">
            <thead>
                <tr>
                    <th>Patient</th>
                    <th>Medecin</th>
                    <th>Date & heure</th>
                    <th>Statut</th>
                    <th class="text-center">Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($appointments as $appointment)
                    @php($status = $appointment->status?->value ?? $appointment->status)
                    <tr>
                        <td>
                            <div class="flex items-center gap-3">
                                <div class="flex h-11 w-11 items-center justify-center rounded-full bg-sky-50 text-sky-600">
                                    <i class="ti ti-user text-lg"></i>
                                </div>
                                <div>
                                    <div class="font-bold text-slate-900">
                                        {{ e($appointment->patient?->first_name ?? '—') }}
                                        {{ e($appointment->patient?->last_name ?? '') }}
                                    </div>
                                    <div class="text-xs text-slate-400">Patient</div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="flex items-center gap-3">
                                <div class="flex h-11 w-11 items-center justify-center rounded-full bg-emerald-50 text-emerald-600">
                                    <i class="ti ti-stethoscope text-lg"></i>
                                </div>
                                <div>
                                    <div class="font-bold text-slate-900">
                                        Dr. {{ e($appointment->doctor?->first_name ?? '—') }}
                                        {{ e($appointment->doctor?->last_name ?? '') }}
                                    </div>
                                    <div class="text-xs text-slate-400">Medecin referent</div>
                                </div>
                            </div>
                        </td>
                        <td class="text-sm">
                            <div class="font-semibold text-slate-800">{{ $appointment->starts_at_utc?->format('d/m/Y') }}</div>
                            <div class="text-xs text-slate-400">
                                {{ $appointment->starts_at_utc?->format('H:i') }} - {{ $appointment->ends_at_utc?->format('H:i') }}
                            </div>
                        </td>
                        <td>
                            @switch($status)
                                @case('DRAFT')
                                    <span class="badge badge-ghost">Brouillon</span>
                                    @break
                                @case('REQUESTED')
                                    <span class="badge badge-warning">En attente</span>
                                    @break
                                @case('CONFIRMED')
                                    <span class="badge badge-success">Confirme</span>
                                    @break
                                @case('COMPLETED')
                                    <span class="badge badge-info">Complete</span>
                                    @break
                                @default
                                    <span class="badge badge-error">Annule</span>
                            @endswitch
                        </td>
                        <td class="text-center">
                            <div class="flex items-center justify-center gap-2">
                                <a href="{{ route('admin.appointments.show', $appointment->id) }}" class="btn btn-ghost btn-sm rounded-xl" title="Voir les details">
                                    <i class="ti ti-eye text-lg"></i>
                                </a>

                                @if(!in_array($status, ['CANCELLED', 'COMPLETED']))
                                    <button class="btn btn-ghost btn-sm rounded-xl text-red-600 hover:bg-red-50 hover:text-red-700" title="Annuler"
                                            onclick="document.getElementById('cancel-modal-{{ $appointment->id }}').showModal()">
                                        <i class="ti ti-x text-lg"></i>
                                    </button>

                                    <dialog id="cancel-modal-{{ $appointment->id }}" class="modal">
                                        <div class="modal-box max-w-xl">
                                            <div class="flex items-start justify-between gap-4">
                                                <div>
                                                    <p class="text-xs font-bold uppercase tracking-[0.18em] text-red-500">Action irreversible</p>
                                                    <h3 class="mt-2 text-2xl font-black tracking-tight text-slate-900">Annuler le rendez-vous</h3>
                                                    <p class="mt-2 text-sm leading-6 text-slate-500">
                                                        Cette action interrompt definitivement la reservation et la rend visible dans le suivi administratif.
                                                    </p>
                                                </div>
                                                <button type="button" class="btn btn-ghost btn-sm btn-circle" onclick="document.getElementById('cancel-modal-{{ $appointment->id }}').close()">
                                                    <i class="ti ti-x"></i>
                                                </button>
                                            </div>

                                            <form method="POST" action="{{ route('admin.appointments.cancel', $appointment->id) }}" class="mt-6 space-y-4">
                                                @csrf
                                                <div class="space-y-2">
                                                    <label class="block text-sm font-bold text-slate-700">Raison de l'annulation</label>
                                                    <textarea
                                                        name="cancel_reason"
                                                        rows="4"
                                                        required
                                                        class="textarea w-full"
                                                        placeholder="Expliquez la raison de l'annulation..."
                                                    ></textarea>
                                                </div>

                                                <div class="flex flex-wrap justify-end gap-3">
                                                    <button type="button" class="btn btn-ghost" onclick="document.getElementById('cancel-modal-{{ $appointment->id }}').close()">
                                                        Fermer
                                                    </button>
                                                    <button type="submit" class="btn btn-error">
                                                        <i class="ti ti-ban text-lg"></i>
                                                        Confirmer l'annulation
                                                    </button>
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
                        <td colspan="5" class="px-6 py-16 text-center">
                            <div class="mx-auto flex max-w-sm flex-col items-center gap-3 text-slate-400">
                                <div class="flex h-16 w-16 items-center justify-center rounded-full bg-slate-100">
                                    <i class="ti ti-calendar-off text-3xl"></i>
                                </div>
                                <div class="text-lg font-bold text-slate-600">Aucun rendez-vous trouve</div>
                                <p class="text-sm leading-6">Ajustez la plage de recherche ou le filtre de statut.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($appointments->hasPages())
        <div class="border-t border-slate-200/70 px-5 py-4 sm:px-6">
            {{ $appointments->withQueryString()->links() }}
        </div>
    @endif
</section>
@endsection
