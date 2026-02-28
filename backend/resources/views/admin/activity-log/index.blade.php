@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Journal d'Activité</h1>
        <p class="text-sm text-base-content/70 mt-1">Audit trail — Traçabilité complète des actions système</p>
    </div>
</div>

<!-- Security Banner -->
<div class="alert shadow-sm mb-6 bg-gradient-to-r from-success/10 to-info/10 border border-success/20">
    <span class="material-symbols-rounded text-success">verified_user</span>
    <div>
        <h3 class="font-bold text-sm">Audit Trail Sécurisé</h3>
        <p class="text-xs">Chaque action critique est enregistrée conformément aux exigences RGPD (Art. 30) et aux normes de sécurité HDS.</p>
    </div>
</div>

<!-- Filters -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.activity-log.index') }}" class="flex flex-col md:flex-row gap-3 flex-wrap">
            <div class="form-control flex-1 min-w-[200px]">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered input-sm w-full" placeholder="Rechercher dans les logs..." />
            </div>
            <select name="log_name" class="select select-bordered select-sm">
                <option value="">Tous les canaux</option>
                @foreach($logNames as $name)
                    <option value="{{ e($name) }}" {{ request('log_name') == $name ? 'selected' : '' }}>{{ e($name) }}</option>
                @endforeach
            </select>
            <select name="event" class="select select-bordered select-sm">
                <option value="">Tous les événements</option>
                @foreach($events as $evt)
                    <option value="{{ e($evt) }}" {{ request('event') == $evt ? 'selected' : '' }}>{{ e($evt) }}</option>
                @endforeach
            </select>
            <input type="date" name="from" value="{{ request('from') }}" class="input input-bordered input-sm" placeholder="Du" />
            <input type="date" name="to" value="{{ request('to') }}" class="input input-bordered input-sm" placeholder="Au" />
            <button type="submit" class="btn btn-primary btn-sm">
                <span class="material-symbols-rounded text-sm">filter_list</span>
                Filtrer
            </button>
            @if(request()->hasAny(['search', 'log_name', 'event', 'from', 'to']))
                <a href="{{ route('admin.activity-log.index') }}" class="btn btn-ghost btn-sm">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Activity Log Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra table-sm">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Date</th>
                        <th class="font-bold">Canal</th>
                        <th class="font-bold">Événement</th>
                        <th class="font-bold">Description</th>
                        <th class="font-bold">Acteur</th>
                        <th class="font-bold">Détails</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($logs as $log)
                        <tr class="hover">
                            <td class="text-xs whitespace-nowrap">
                                {{ \Carbon\Carbon::parse($log->created_at)->format('d/m/Y H:i:s') }}
                            </td>
                            <td>
                                @switch($log->log_name)
                                    @case('security')
                                        <span class="badge badge-error badge-xs">security</span>
                                        @break
                                    @case('default')
                                        <span class="badge badge-info badge-xs">default</span>
                                        @break
                                    @default
                                        <span class="badge badge-ghost badge-xs">{{ e($log->log_name) }}</span>
                                @endswitch
                            </td>
                            <td>
                                <span class="badge badge-outline badge-xs font-mono">{{ e($log->event ?? '—') }}</span>
                            </td>
                            <td class="text-sm max-w-[300px] truncate">
                                {{ e($log->description ?? '—') }}
                            </td>
                            <td class="text-xs">
                                @if($log->causer_id)
                                    <span class="font-mono bg-base-200 px-1.5 py-0.5 rounded text-xs">{{ Str::limit($log->causer_id, 8) }}</span>
                                @else
                                    <span class="text-gray-400">Système</span>
                                @endif
                            </td>
                            <td>
                                @if($log->properties && $log->properties !== '[]' && $log->properties !== '{}')
                                    <div x-data="{ open: false }">
                                        <button @click="open = !open" class="btn btn-ghost btn-xs">
                                            <span class="material-symbols-rounded text-xs">data_object</span>
                                        </button>
                                        <div x-show="open" x-transition class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center" @click.self="open = false">
                                            <div class="bg-base-100 rounded-xl shadow-2xl p-6 max-w-lg w-full mx-4 max-h-[80vh] overflow-auto">
                                                <div class="flex justify-between items-center mb-4">
                                                    <h3 class="font-bold text-lg">Propriétés JSON</h3>
                                                    <button @click="open = false" class="btn btn-ghost btn-sm btn-circle">
                                                        <span class="material-symbols-rounded">close</span>
                                                    </button>
                                                </div>
                                                <pre class="bg-base-200 p-3 rounded-lg text-xs font-mono overflow-auto max-h-[400px]">{{ json_encode(json_decode($log->properties), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) }}</pre>
                                            </div>
                                        </div>
                                    </div>
                                @else
                                    <span class="text-gray-400 text-xs">—</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">receipt_long</span>
                                Aucune entrée dans le journal.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($logs->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $logs->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
