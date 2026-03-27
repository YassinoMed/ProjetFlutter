@extends('admin.layouts.app')

@section('page-title', 'Gestion des utilisateurs')

@section('content')
<div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
    <div>
        <p class="text-xs font-bold uppercase tracking-[0.22em] text-slate-400">Gestion des identites</p>
        <h1 class="mt-2 text-3xl font-black tracking-tight text-slate-950">Utilisateurs, medecins et comptes sensibles</h1>
        <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-500">
            Filtrez les profils, inspectez les roles et naviguez plus rapidement dans la base utilisateurs du produit.
        </p>
    </div>

    <div class="flex items-center gap-3">
        <div class="pill pill-primary">
            <i class="ti ti-users"></i>
            {{ $users->total() }} comptes
        </div>
    </div>
</div>

<section class="filter-shell mb-6">
    <div class="p-5 sm:p-6">
        <form method="GET" action="{{ route('admin.users.index') }}" class="grid gap-3 xl:grid-cols-[minmax(0,1fr)_220px_auto_auto]">
            <div class="relative">
                <i class="ti ti-search absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"></i>
                <input
                    type="text"
                    name="search"
                    value="{{ request('search') }}"
                    class="input h-12 w-full pl-11"
                    placeholder="Rechercher un nom, un email ou un identifiant..."
                />
            </div>

            <select name="role" class="select h-12 w-full">
                <option value="">Tous les roles</option>
                <option value="PATIENT" {{ request('role') == 'PATIENT' ? 'selected' : '' }}>Patients</option>
                <option value="DOCTOR" {{ request('role') == 'DOCTOR' ? 'selected' : '' }}>Medecins</option>
                <option value="SECRETARY" {{ request('role') == 'SECRETARY' ? 'selected' : '' }}>Secretaires</option>
                <option value="ADMIN" {{ request('role') == 'ADMIN' ? 'selected' : '' }}>Admins</option>
            </select>

            <button type="submit" class="btn btn-primary h-12">
                <i class="ti ti-adjustments-horizontal text-lg"></i>
                Filtrer
            </button>

            @if(request()->hasAny(['search', 'role']))
                <a href="{{ route('admin.users.index') }}" class="btn btn-ghost h-12">
                    <i class="ti ti-rotate-2 text-lg"></i>
                    Reinitialiser
                </a>
            @endif
        </form>
    </div>
</section>

<section class="table-shell">
    <div class="border-b border-slate-200/70 px-5 py-4 sm:px-6">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <h2 class="text-lg font-extrabold text-slate-900">Base utilisateurs</h2>
                <p class="text-sm text-slate-500">Vue d'ensemble des comptes actifs et des roles metier.</p>
            </div>
        </div>
    </div>

    <div class="overflow-x-auto">
        <table class="table table-zebra">
            <thead>
                <tr>
                    <th>Utilisateur</th>
                    <th>Email</th>
                    <th>Role</th>
                    <th>Telephone</th>
                    <th>Inscrit le</th>
                    <th class="text-center">Actions</th>
                </tr>
            </thead>
            <tbody>
                @forelse($users as $user)
                    @php($role = $user->role?->value ?? $user->role)
                    <tr>
                        <td>
                            <div class="flex items-center gap-3">
                                <div class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-50 text-sm font-extrabold text-blue-700">
                                    {{ strtoupper(substr($user->first_name, 0, 1)) }}{{ strtoupper(substr($user->last_name, 0, 1)) }}
                                </div>
                                <div>
                                    <div class="font-bold text-slate-900">{{ e($user->first_name) }} {{ e($user->last_name) }}</div>
                                    <div class="text-xs font-medium text-slate-400">{{ Str::limit($user->id, 10) }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="text-sm font-medium text-slate-600">{{ e($user->email) }}</td>
                        <td>
                            @switch($role)
                                @case('PATIENT')
                                    <span class="badge badge-info">
                                        <i class="ti ti-user text-sm"></i>
                                        Patient
                                    </span>
                                    @break
                                @case('DOCTOR')
                                    <span class="badge badge-success">
                                        <i class="ti ti-stethoscope text-sm"></i>
                                        Medecin
                                    </span>
                                    @break
                                @case('SECRETARY')
                                    <span class="badge badge-warning">
                                        <i class="ti ti-briefcase text-sm"></i>
                                        Secretaire
                                    </span>
                                    @break
                                @default
                                    <span class="badge badge-ghost">
                                        <i class="ti ti-shield text-sm"></i>
                                        Admin
                                    </span>
                            @endswitch
                        </td>
                        <td class="text-sm text-slate-600">{{ e($user->phone) ?? '—' }}</td>
                        <td class="text-sm">
                            <div class="font-semibold text-slate-700">{{ $user->created_at?->format('d/m/Y') ?? '—' }}</div>
                            <div class="text-xs text-slate-400">{{ $user->created_at?->format('H:i') ?? '' }}</div>
                        </td>
                        <td class="text-center">
                            <a href="{{ route('admin.users.show', $user->id) }}" class="btn btn-ghost btn-sm rounded-xl" title="Voir le profil">
                                <i class="ti ti-eye text-lg"></i>
                            </a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-16 text-center">
                            <div class="mx-auto flex max-w-sm flex-col items-center gap-3 text-slate-400">
                                <div class="flex h-16 w-16 items-center justify-center rounded-full bg-slate-100">
                                    <i class="ti ti-user-off text-3xl"></i>
                                </div>
                                <div class="text-lg font-bold text-slate-600">Aucun utilisateur trouve</div>
                                <p class="text-sm leading-6">Ajustez les filtres ou effectuez une recherche plus large.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($users->hasPages())
        <div class="border-t border-slate-200/70 px-5 py-4 sm:px-6">
            {{ $users->withQueryString()->links() }}
        </div>
    @endif
</section>
@endsection
