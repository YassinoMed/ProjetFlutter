@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Dossiers Médicaux</h1>
        <p class="text-sm text-base-content/70 mt-1">Vue d'ensemble des métadonnées – contenu chiffré E2EE</p>
    </div>
</div>

<!-- E2EE Alert -->
<div class="alert alert-info shadow-sm mb-6">
    <span class="material-symbols-rounded">enhanced_encryption</span>
    <div>
        <h3 class="font-bold text-sm">Données Chiffrées E2EE</h3>
        <p class="text-xs">Le contenu médical est chiffré de bout en bout. Seules les métadonnées (catégorie, dates, participants) sont accessibles. Conformité HDS & RGPD.</p>
    </div>
</div>

<!-- Stats Cards -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Total Dossiers</div>
                    <div class="text-2xl font-bold text-primary mt-1">{{ number_format($stats['total']) }}</div>
                </div>
                <div class="bg-primary/10 p-3 rounded-xl text-primary">
                    <span class="material-symbols-rounded text-2xl">folder_shared</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Dossiers Actifs</div>
                    <div class="text-2xl font-bold text-success mt-1">{{ number_format($stats['active']) }}</div>
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
                    <div class="text-xs text-gray-400 font-bold uppercase">Expirés (RGPD TTL)</div>
                    <div class="text-2xl font-bold text-error mt-1">{{ number_format($stats['expired']) }}</div>
                </div>
                <div class="bg-error/10 p-3 rounded-xl text-error">
                    <span class="material-symbols-rounded text-2xl">timer_off</span>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.medical-records.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher un patient..." />
            </div>
            <select name="category" class="select select-bordered">
                <option value="">Toutes les catégories</option>
                @foreach($stats['categories'] as $cat)
                    <option value="{{ e($cat) }}" {{ request('category') == $cat ? 'selected' : '' }}>{{ e($cat) }}</option>
                @endforeach
            </select>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">filter_list</span>
                Filtrer
            </button>
            @if(request()->hasAny(['search', 'category']))
                <a href="{{ route('admin.medical-records.index') }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Records Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Patient</th>
                        <th class="font-bold">Médecin</th>
                        <th class="font-bold">Catégorie</th>
                        <th class="font-bold">Date Enregistrement</th>
                        <th class="font-bold">Expiration</th>
                        <th class="font-bold">Chiffrement</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($records as $record)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-info">person</span>
                                    <span class="font-medium text-sm">
                                        {{ e($record->patient?->first_name ?? '—') }} {{ e($record->patient?->last_name ?? '') }}
                                    </span>
                                </div>
                            </td>
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-success">stethoscope</span>
                                    <span class="text-sm">
                                        Dr. {{ e($record->doctor?->first_name ?? '—') }} {{ e($record->doctor?->last_name ?? '') }}
                                    </span>
                                </div>
                            </td>
                            <td>
                                <span class="badge badge-ghost badge-sm">{{ e($record->category ?? '—') }}</span>
                            </td>
                            <td class="text-sm">
                                {{ $record->recorded_at_utc?->format('d/m/Y H:i') ?? '—' }}
                            </td>
                            <td class="text-sm">
                                @if($record->expires_at)
                                    <span class="text-xs {{ $record->expires_at->isPast() ? 'text-error font-bold' : 'text-gray-400' }}">
                                        {{ $record->expires_at->format('d/m/Y') }}
                                        @if($record->expires_at->isPast())
                                            <span class="badge badge-error badge-xs ml-1">Expiré</span>
                                        @endif
                                    </span>
                                @else
                                    <span class="text-xs text-gray-400">Aucune</span>
                                @endif
                            </td>
                            <td>
                                <div class="flex items-center gap-1">
                                    <span class="material-symbols-rounded text-xs text-success">lock</span>
                                    <span class="text-xs text-success font-mono">E2EE</span>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">folder_off</span>
                                Aucun dossier médical trouvé.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($records->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $records->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
