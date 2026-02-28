@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Push Notifications</h1>
        <p class="text-sm text-base-content/70 mt-1">Gestion des tokens FCM et appareils enregistrés</p>
    </div>
</div>

<!-- Stats Cards -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Appareils Enregistrés</div>
                    <div class="text-2xl font-bold text-primary mt-1">{{ $stats['total_devices'] }}</div>
                </div>
                <div class="bg-primary/10 p-3 rounded-xl text-primary">
                    <span class="material-symbols-rounded text-2xl">devices</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Actifs Aujourd'hui</div>
                    <div class="text-2xl font-bold text-success mt-1">{{ $stats['active_today'] }}</div>
                </div>
                <div class="bg-success/10 p-3 rounded-xl text-success">
                    <span class="material-symbols-rounded text-2xl">notifications_active</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Utilisateurs Uniques</div>
                    <div class="text-2xl font-bold text-info mt-1">{{ $stats['unique_users'] }}</div>
                </div>
                <div class="bg-info/10 p-3 rounded-xl text-info">
                    <span class="material-symbols-rounded text-2xl">group</span>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.notifications.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher un utilisateur..." />
            </div>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">search</span>
                Rechercher
            </button>
            @if(request('search'))
                <a href="{{ route('admin.notifications.index') }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Tokens Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Utilisateur</th>
                        <th class="font-bold">Plateforme</th>
                        <th class="font-bold">Token (partiel)</th>
                        <th class="font-bold">Dernière Activité</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($tokens as $token)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-primary">person</span>
                                    <div>
                                        <span class="font-medium text-sm">
                                            {{ e($token->user?->first_name ?? '—') }} {{ e($token->user?->last_name ?? '') }}
                                        </span>
                                        <div class="text-xs text-gray-400">{{ e($token->user?->email ?? '') }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <span class="badge badge-ghost badge-sm">{{ e($token->platform ?? 'unknown') }}</span>
                            </td>
                            <td>
                                <span class="font-mono text-xs bg-base-200 px-2 py-1 rounded">
                                    {{ Str::limit($token->token ?? '', 20, '…') }}
                                </span>
                            </td>
                            <td class="text-sm">
                                {{ $token->last_seen_at_utc?->diffForHumans() ?? ($token->updated_at?->diffForHumans() ?? '—') }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">notifications_off</span>
                                Aucun appareil enregistré.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($tokens->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $tokens->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
