@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Gestion des Utilisateurs</h1>
        <p class="text-sm text-base-content/70 mt-1">Patients, Médecins et Administrateurs</p>
    </div>
</div>

<!-- Filters + Search  -->
<div class="card bg-base-100 shadow-sm border border-base-200 mb-6">
    <div class="card-body p-4">
        <form method="GET" action="{{ route('admin.users.index') }}" class="flex flex-col md:flex-row gap-3">
            <div class="form-control flex-1">
                <input type="text" name="search" value="{{ request('search') }}"
                       class="input input-bordered w-full" placeholder="Rechercher par nom ou email..." />
            </div>
            <select name="role" class="select select-bordered">
                <option value="">Tous les rôles</option>
                <option value="PATIENT" {{ request('role') == 'PATIENT' ? 'selected' : '' }}>Patients</option>
                <option value="DOCTOR" {{ request('role') == 'DOCTOR' ? 'selected' : '' }}>Médecins</option>
                <option value="ADMIN" {{ request('role') == 'ADMIN' ? 'selected' : '' }}>Admins</option>
            </select>
            <button type="submit" class="btn btn-primary">
                <span class="material-symbols-rounded text-sm">search</span>
                Filtrer
            </button>
            @if(request()->hasAny(['search', 'role']))
                <a href="{{ route('admin.users.index') }}" class="btn btn-ghost">
                    <span class="material-symbols-rounded text-sm">close</span>
                    Réinitialiser
                </a>
            @endif
        </form>
    </div>
</div>

<!-- Users Table -->
<div class="card bg-base-100 shadow-sm border border-base-200">
    <div class="card-body p-0">
        <div class="overflow-x-auto">
            <table class="table table-zebra">
                <thead>
                    <tr class="bg-base-200/50">
                        <th class="font-bold">Utilisateur</th>
                        <th class="font-bold">Email</th>
                        <th class="font-bold">Rôle</th>
                        <th class="font-bold">Téléphone</th>
                        <th class="font-bold">Inscrit le</th>
                        <th class="font-bold text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($users as $user)
                        <tr class="hover">
                            <td>
                                <div class="flex items-center gap-3">
                                    <div class="avatar">
                                        <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                                            <span class="font-bold text-primary text-sm">{{ strtoupper(substr($user->first_name, 0, 1)) }}{{ strtoupper(substr($user->last_name, 0, 1)) }}</span>
                                        </div>
                                    </div>
                                    <div>
                                        <div class="font-bold text-sm">{{ e($user->first_name) }} {{ e($user->last_name) }}</div>
                                        <div class="text-xs opacity-50">{{ Str::limit($user->id, 8) }}</div>
                                    </div>
                                </div>
                            </td>
                            <td class="text-sm">{{ e($user->email) }}</td>
                            <td>
                                @switch($user->role?->value ?? $user->role)
                                    @case('PATIENT')
                                        <span class="badge badge-info badge-sm gap-1">
                                            <span class="material-symbols-rounded text-xs">person</span>
                                            Patient
                                        </span>
                                        @break
                                    @case('DOCTOR')
                                        <span class="badge badge-success badge-sm gap-1">
                                            <span class="material-symbols-rounded text-xs">stethoscope</span>
                                            Médecin
                                        </span>
                                        @break
                                    @case('ADMIN')
                                        <span class="badge badge-warning badge-sm gap-1">
                                            <span class="material-symbols-rounded text-xs">shield</span>
                                            Admin
                                        </span>
                                        @break
                                @endswitch
                            </td>
                            <td class="text-sm">{{ e($user->phone) ?? '—' }}</td>
                            <td class="text-sm">{{ $user->created_at?->format('d/m/Y H:i') ?? '—' }}</td>
                            <td class="text-center">
                                <a href="{{ route('admin.users.show', $user->id) }}" class="btn btn-ghost btn-sm btn-circle" title="Détails">
                                    <span class="material-symbols-rounded text-sm">visibility</span>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-8 text-gray-400">
                                <span class="material-symbols-rounded text-4xl mb-2 block">person_off</span>
                                Aucun utilisateur trouvé.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($users->hasPages())
            <div class="p-4 border-t border-base-200">
                {{ $users->withQueryString()->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
