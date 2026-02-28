@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Droit à l'Oubli / RGPD</h1>
        <p class="text-sm text-base-content/70 mt-1">Gestion des consentements et conformité RGPD</p>
    </div>
</div>

<!-- RGPD Banner -->
<div class="alert shadow-sm mb-6 bg-gradient-to-r from-primary/10 to-secondary/10 border border-primary/20">
    <span class="material-symbols-rounded text-primary">gavel</span>
    <div>
        <h3 class="font-bold text-sm">Conformité RGPD – Règlement Européen 2016/679</h3>
        <p class="text-xs">Toutes les opérations d'anonymisation et de suppression sont journalisées dans les logs de sécurité (audit trail).</p>
    </div>
</div>

<!-- Stats Cards -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Consentements Actifs</div>
                    <div class="text-2xl font-bold text-success mt-1">{{ $stats['total_consents'] }}</div>
                </div>
                <div class="bg-success/10 p-3 rounded-xl text-success">
                    <span class="material-symbols-rounded text-2xl">check_circle</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Consentements Révoqués</div>
                    <div class="text-2xl font-bold text-error mt-1">{{ $stats['total_revoked'] }}</div>
                </div>
                <div class="bg-error/10 p-3 rounded-xl text-error">
                    <span class="material-symbols-rounded text-2xl">remove_circle</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Comptes Supprimés</div>
                    <div class="text-2xl font-bold text-warning mt-1">{{ $stats['pending_deletion_requests'] }}</div>
                </div>
                <div class="bg-warning/10 p-3 rounded-xl text-warning">
                    <span class="material-symbols-rounded text-2xl">person_off</span>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.rgpd.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher un utilisateur..." />
            </div>
            <select name="consent_type" class="select select-bordered">
                <option value="">Tous les types</option>
                <option value="data_processing" {{ request('consent_type') == 'data_processing' ? 'selected' : '' }}>Traitement des données</option>
                <option value="marketing" {{ request('consent_type') == 'marketing' ? 'selected' : '' }}>Marketing</option>
                <option value="medical_records" {{ request('consent_type') == 'medical_records' ? 'selected' : '' }}>Dossiers médicaux</option>
                <option value="analytics" {{ request('consent_type') == 'analytics' ? 'selected' : '' }}>Analytiques</option>
            </select>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">filter_list</span>
                Filtrer
            </button>
            @if(request()->hasAny(['search', 'consent_type']))
                <a href="{{ route('admin.rgpd.index') }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Consents Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Utilisateur</th>
                        <th class="font-bold">Type de consentement</th>
                        <th class="font-bold">Statut</th>
                        <th class="font-bold">Date</th>
                        <th class="font-bold text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($consents as $consent)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-primary">person</span>
                                    <div>
                                        <span class="font-medium text-sm">
                                            {{ e($consent->user?->first_name ?? '—') }} {{ e($consent->user?->last_name ?? '') }}
                                        </span>
                                        <div class="text-xs text-gray-400">{{ e($consent->user?->email ?? '') }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <span class="badge badge-ghost badge-sm">{{ e($consent->consent_type) }}</span>
                            </td>
                            <td>
                                @if($consent->consented)
                                    <span class="badge badge-success badge-sm gap-1">
                                        <span class="material-symbols-rounded text-xs">check</span>
                                        Accordé
                                    </span>
                                @else
                                    <span class="badge badge-error badge-sm gap-1">
                                        <span class="material-symbols-rounded text-xs">close</span>
                                        Révoqué
                                    </span>
                                @endif
                            </td>
                            <td class="text-sm">
                                @if($consent->consented && $consent->consented_at_utc)
                                    {{ $consent->consented_at_utc->format('d/m/Y H:i') }}
                                @elseif($consent->revoked_at_utc)
                                    {{ $consent->revoked_at_utc->format('d/m/Y H:i') }}
                                @else
                                    —
                                @endif
                            </td>
                            <td class="text-center">
                                @if($consent->user)
                                    <button class="btn btn-ghost btn-sm text-error" title="Anonymiser"
                                            onclick="document.getElementById('anon-modal-{{ $consent->id }}').showModal()">
                                        <span class="material-symbols-rounded text-sm">delete_forever</span>
                                    </button>

                                    <!-- Anonymize Modal -->
                                    <dialog id="anon-modal-{{ $consent->id }}" class="modal">
                                        <div class="modal-box">
                                            <h3 class="font-bold text-lg text-error">
                                                <span class="material-symbols-rounded align-middle">warning</span>
                                                Anonymisation RGPD
                                            </h3>
                                            <p class="py-4 text-sm">
                                                Cette action est <strong>irréversible</strong>. Les données personnelles de
                                                <strong>{{ e($consent->user->first_name) }} {{ e($consent->user->last_name) }}</strong>
                                                seront définitivement anonymisées conformément à l'Art. 17 du RGPD.
                                            </p>
                                            <form method="POST" action="{{ route('admin.rgpd.anonymize', $consent->user->id) }}">
                                                @csrf
                                                <div class="form-control mb-4">
                                                    <label class="label"><span class="label-text">Justification légale</span></label>
                                                    <textarea name="reason" rows="3" required
                                                              class="textarea textarea-bordered" placeholder="Art. 17 RGPD – Droit à l'effacement..."></textarea>
                                                </div>
                                                <div class="modal-action">
                                                    <button type="button" class="btn btn-ghost"
                                                            onclick="document.getElementById('anon-modal-{{ $consent->id }}').close()">Annuler</button>
                                                    <button type="submit" class="btn btn-error">Anonymiser définitivement</button>
                                                </div>
                                            </form>
                                        </div>
                                        <form method="dialog" class="modal-backdrop"><button>close</button></form>
                                    </dialog>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">shield_person</span>
                                Aucun consentement enregistré.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($consents->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $consents->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
