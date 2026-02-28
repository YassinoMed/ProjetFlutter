@extends('admin.layouts.app')

@section('content')
<div class="mb-6">
    <a href="{{ route('admin.users.index') }}" class="btn btn-ghost btn-sm gap-1 mb-4">
        <span class="material-symbols-rounded text-sm">arrow_back</span>
        Retour à la liste
    </a>
    <h1 class="text-3xl font-bold text-base-content">Profil Utilisateur</h1>
    <p class="text-sm text-base-content/70 mt-1">Détails complets de l'utilisateur</p>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Main Info Card -->
    <div class="card bg-base-100 shadow-sm border border-base-200 lg:col-span-2">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-primary">person</span>
                Informations Personnelles
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Prénom</label>
                    <p class="text-lg font-semibold">{{ e($user->first_name) }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Nom</label>
                    <p class="text-lg font-semibold">{{ e($user->last_name) }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Email</label>
                    <p class="text-lg">{{ e($user->email) }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Téléphone</label>
                    <p class="text-lg">{{ e($user->phone) ?? '—' }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Rôle</label>
                    <p class="mt-1">
                        @switch($user->role?->value ?? $user->role)
                            @case('PATIENT')
                                <span class="badge badge-info gap-1">
                                    <span class="material-symbols-rounded text-sm">person</span> Patient
                                </span>
                                @break
                            @case('DOCTOR')
                                <span class="badge badge-success gap-1">
                                    <span class="material-symbols-rounded text-sm">stethoscope</span> Médecin
                                </span>
                                @break
                            @case('ADMIN')
                                <span class="badge badge-warning gap-1">
                                    <span class="material-symbols-rounded text-sm">shield</span> Admin
                                </span>
                                @break
                        @endswitch
                    </p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Inscrit le</label>
                    <p class="text-lg">{{ $user->created_at?->format('d/m/Y à H:i') ?? '—' }}</p>
                </div>
            </div>

            <div class="mt-4">
                <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Identifiant UUID</label>
                <p class="font-mono text-sm bg-base-200 p-2 rounded mt-1">{{ $user->id }}</p>
            </div>
        </div>
    </div>

    <!-- Side Stats Card -->
    <div class="space-y-6">
        <!-- Doctor Profile extras -->
        @if(($user->role?->value ?? $user->role) === 'DOCTOR' && isset($extra['doctor']))
            <div class="card bg-base-100 shadow-sm border border-base-200">
                <div class="card-body">
                    <h3 class="card-title text-md font-bold">
                        <span class="material-symbols-rounded text-success">stethoscope</span>
                        Profil Médecin
                    </h3>
                    <div class="space-y-3 mt-2">
                        <div>
                            <label class="text-xs font-bold text-gray-400">RPPS</label>
                            <p class="font-mono">{{ e($extra['doctor']->rpps ?? '—') }}</p>
                        </div>
                        <div>
                            <label class="text-xs font-bold text-gray-400">Spécialité</label>
                            <p>{{ e($extra['doctor']->specialty ?? '—') }}</p>
                        </div>
                        <div>
                            <label class="text-xs font-bold text-gray-400">Ville</label>
                            <p>{{ e($extra['doctor']->city ?? '—') }}</p>
                        </div>
                        <div>
                            <label class="text-xs font-bold text-gray-400">Tarif Consultation</label>
                            <p class="text-primary font-bold">{{ $extra['doctor']->consultation_fee ?? '—' }} €</p>
                        </div>
                        <div>
                            <label class="text-xs font-bold text-gray-400">Note</label>
                            <div class="flex items-center gap-1">
                                <span class="material-symbols-rounded text-warning text-sm">star</span>
                                <span class="font-bold">{{ $extra['doctor']->rating ?? '—' }}</span>
                                <span class="text-xs text-gray-400">({{ $extra['doctor']->total_reviews ?? 0 }} avis)</span>
                            </div>
                        </div>
                        <div>
                            <label class="text-xs font-bold text-gray-400">Vidéo Consultation</label>
                            @if($extra['doctor']->is_available_for_video ?? false)
                                <span class="badge badge-success badge-sm">Disponible</span>
                            @else
                                <span class="badge badge-error badge-sm">Indisponible</span>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        @endif

        <!-- Patient Profile extras -->
        @if(($user->role?->value ?? $user->role) === 'PATIENT' && isset($extra['patient']))
            <div class="card bg-base-100 shadow-sm border border-base-200">
                <div class="card-body">
                    <h3 class="card-title text-md font-bold">
                        <span class="material-symbols-rounded text-info">person</span>
                        Profil Patient
                    </h3>
                    <div class="space-y-3 mt-2">
                        <div>
                            <label class="text-xs font-bold text-gray-400">Date de naissance</label>
                            <p>{{ $extra['patient']->date_of_birth?->format('d/m/Y') ?? '—' }}</p>
                        </div>
                        <div>
                            <label class="text-xs font-bold text-gray-400">Sexe</label>
                            <p>{{ e($extra['patient']->sex ?? '—') }}</p>
                        </div>
                    </div>
                </div>
            </div>
        @endif

        <!-- Quick Actions -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body">
                <h3 class="card-title text-md font-bold">
                    <span class="material-symbols-rounded text-warning">bolt</span>
                    Actions Rapides
                </h3>
                <div class="space-y-2 mt-2">
                    <a href="{{ route('admin.appointments.index', ['search' => $user->email]) }}" class="btn btn-outline btn-sm w-full justify-start gap-2">
                        <span class="material-symbols-rounded text-sm">event</span>
                        Voir les rendez-vous
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
