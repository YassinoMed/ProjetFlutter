@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Approbation des Médecins</h1>
        <p class="text-sm text-base-content/70 mt-1">Vérification et validation des profils médecins (RPPS)</p>
    </div>
</div>

<!-- Stats Cards -->
<div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
    <div class="card bg-base-100 shadow-sm border border-base-200 {{ $status === 'pending' ? 'ring-2 ring-warning' : '' }}">
        <a href="{{ route('admin.doctors.index', ['status' => 'pending']) }}" class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">En Attente</div>
            <div class="text-2xl font-bold text-warning mt-1">{{ $stats['pending'] }}</div>
        </a>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200 {{ $status === 'approved' ? 'ring-2 ring-success' : '' }}">
        <a href="{{ route('admin.doctors.index', ['status' => 'approved']) }}" class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">Approuvés</div>
            <div class="text-2xl font-bold text-success mt-1">{{ $stats['approved'] }}</div>
        </a>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200 {{ $status === 'rejected' ? 'ring-2 ring-error' : '' }}">
        <a href="{{ route('admin.doctors.index', ['status' => 'rejected']) }}" class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">Refusés</div>
            <div class="text-2xl font-bold text-error mt-1">{{ $stats['rejected'] }}</div>
        </a>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="text-xs text-gray-400 font-bold uppercase">Total Médecins</div>
            <div class="text-2xl font-bold text-primary mt-1">{{ $stats['total'] }}</div>
        </div>
    </div>
</div>

<!-- Search -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.doctors.index') }}" class="flex flex-col md:flex-row gap-3">
            <input type="hidden" name="status" value="{{ $status }}" />
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher par nom, email ou RPPS..." />
            </div>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">search</span>
                Rechercher
            </button>
            @if(request('search'))
                <a href="{{ route('admin.doctors.index', ['status' => $status]) }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Doctors Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Médecin</th>
                        <th class="font-bold">RPPS</th>
                        <th class="font-bold">Spécialité</th>
                        <th class="font-bold">Ville</th>
                        <th class="font-bold">Inscrit le</th>
                        <th class="font-bold text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($doctors as $doctor)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-3">
                                    <div class="avatar">
                                        <div class="w-10 h-10 rounded-full bg-success/10 flex items-center justify-center">
                                            <span class="font-bold text-success text-sm">Dr</span>
                                        </div>
                                    </div>
                                    <div>
                                        <div class="font-bold text-sm">
                                            Dr. {{ e($doctor->user?->first_name ?? '—') }} {{ e($doctor->user?->last_name ?? '') }}
                                        </div>
                                        <div class="text-xs opacity-50">{{ e($doctor->user?->email ?? '') }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <span class="font-mono text-sm bg-base-200 px-2 py-1 rounded">
                                    {{ e($doctor->rpps ?? '—') }}
                                </span>
                            </td>
                            <td class="text-sm">{{ e($doctor->specialty ?? '—') }}</td>
                            <td class="text-sm">{{ e($doctor->city ?? '—') }}</td>
                            <td class="text-sm">{{ $doctor->created_at?->format('d/m/Y') ?? '—' }}</td>
                            <td class="text-center">
                                <div class="flex items-center justify-center gap-1">
                                    <a href="{{ route('admin.doctors.show', $doctor->user_id) }}" class="btn btn-ghost btn-sm btn-circle" title="Détails">
                                        <span class="material-symbols-rounded text-sm">visibility</span>
                                    </a>

                                    @if($status === 'pending')
                                        <!-- Approve Button -->
                                        <form method="POST" action="{{ route('admin.doctors.approve', $doctor->user_id) }}" class="inline">
                                            @csrf
                                            <button type="submit" class="btn btn-ghost btn-sm btn-circle text-success" title="Approuver">
                                                <span class="material-symbols-rounded text-sm">check_circle</span>
                                            </button>
                                        </form>

                                        <!-- Reject Button -->
                                        <button class="btn btn-ghost btn-sm btn-circle text-error" title="Refuser"
                                                onclick="document.getElementById('reject-modal-{{ $doctor->user_id }}').showModal()">
                                            <span class="material-symbols-rounded text-sm">cancel</span>
                                        </button>

                                        <!-- Reject Modal -->
                                        <dialog id="reject-modal-{{ $doctor->user_id }}" class="modal">
                                            <div class="modal-box">
                                                <h3 class="font-bold text-lg text-error">
                                                    <span class="material-symbols-rounded align-middle">gpp_bad</span>
                                                    Refuser le médecin
                                                </h3>
                                                <p class="py-2 text-sm">
                                                    Dr. {{ e($doctor->user?->first_name ?? '') }} {{ e($doctor->user?->last_name ?? '') }}
                                                    – RPPS : {{ e($doctor->rpps ?? '—') }}
                                                </p>
                                                <form method="POST" action="{{ route('admin.doctors.reject', $doctor->user_id) }}">
                                                    @csrf
                                                    <div class="form-control mb-4">
                                                        <label class="label"><span class="label-text">Motif du refus</span></label>
                                                        <textarea name="rejection_reason" rows="3" required
                                                                  class="textarea textarea-bordered"
                                                                  placeholder="Ex: Numéro RPPS invalide, documents manquants..."></textarea>
                                                    </div>
                                                    <div class="modal-action">
                                                        <button type="button" class="btn btn-ghost"
                                                                onclick="document.getElementById('reject-modal-{{ $doctor->user_id }}').close()">Annuler</button>
                                                        <button type="submit" class="btn btn-error">Confirmer le refus</button>
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
                            <td colspan="6" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">stethoscope</span>
                                Aucun médecin trouvé dans cette catégorie.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($doctors->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $doctors->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
