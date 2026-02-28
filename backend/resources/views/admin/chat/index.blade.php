@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Supervision des Messages</h1>
        <p class="text-sm text-base-content/70 mt-1">Monitoring des communications chiffrées E2EE</p>
    </div>
</div>

<!-- Alert E2EE -->
<div class="alert alert-info shadow-sm mb-6">
    <span class="material-symbols-rounded">lock</span>
    <div>
        <h3 class="font-bold text-sm">Chiffrement de Bout en Bout (E2EE)</h3>
        <p class="text-xs">Les contenus des messages sont chiffrés. Seuls les métadonnées (expéditeur, date, consultation) sont accessibles pour la supervision.</p>
    </div>
</div>

<!-- Stats Cards -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Messages Aujourd'hui</div>
                    <div class="text-2xl font-bold text-primary mt-1">{{ $stats['total_today'] }}</div>
                </div>
                <div class="bg-primary/10 p-3 rounded-xl text-primary">
                    <span class="material-symbols-rounded text-2xl">chat</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Messages (7j)</div>
                    <div class="text-2xl font-bold text-secondary mt-1">{{ $stats['total_week'] }}</div>
                </div>
                <div class="bg-secondary/10 p-3 rounded-xl text-secondary">
                    <span class="material-symbols-rounded text-2xl">inbox</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Consultations Actives</div>
                    <div class="text-2xl font-bold text-accent mt-1">{{ $stats['active_consultations'] }}</div>
                </div>
                <div class="bg-accent/10 p-3 rounded-xl text-accent">
                    <span class="material-symbols-rounded text-2xl">forum</span>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.chat.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher par expéditeur..." />
            </div>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">search</span>
                Rechercher
            </button>
            @if(request()->hasAny(['search', 'flagged_only']))
                <a href="{{ route('admin.chat.index') }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Messages Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Expéditeur</th>
                        <th class="font-bold">Destinataire</th>
                        <th class="font-bold">Consultation</th>
                        <th class="font-bold">Date d'envoi</th>
                        <th class="font-bold">Algo E2EE</th>
                        <th class="font-bold">Expiration</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($messages as $message)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-primary">person</span>
                                    <span class="text-sm font-medium">
                                        {{ e($message->sender?->first_name ?? '—') }} {{ e($message->sender?->last_name ?? '') }}
                                    </span>
                                </div>
                            </td>
                            <td>
                                <div class="flex items-center gap-2">
                                    <span class="material-symbols-rounded text-sm text-secondary">person</span>
                                    <span class="text-sm">
                                        {{ e($message->recipient?->first_name ?? '—') }} {{ e($message->recipient?->last_name ?? '') }}
                                    </span>
                                </div>
                            </td>
                            <td>
                                <span class="font-mono text-xs bg-base-200 px-2 py-1 rounded">
                                    {{ Str::limit($message->consultation_id, 8) }}
                                </span>
                            </td>
                            <td class="text-sm">
                                {{ $message->sent_at_utc?->format('d/m/Y H:i') ?? '—' }}
                            </td>
                            <td>
                                <span class="badge badge-ghost badge-sm">{{ e($message->algorithm ?? 'AES-GCM') }}</span>
                            </td>
                            <td class="text-sm">
                                @if($message->expires_at)
                                    <span class="text-xs {{ $message->expires_at->isPast() ? 'text-error' : 'text-gray-400' }}">
                                        {{ $message->expires_at->format('d/m/Y') }}
                                    </span>
                                @else
                                    <span class="text-xs text-gray-400">—</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">chat_bubble_outline</span>
                                Aucun message trouvé.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($messages->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $messages->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
