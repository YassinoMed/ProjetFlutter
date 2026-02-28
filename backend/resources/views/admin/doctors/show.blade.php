@extends('admin.layouts.app')

@section('content')
<div class="mb-6">
    <a href="{{ route('admin.doctors.index') }}" class="btn btn-ghost btn-sm gap-1 mb-4">
        <span class="material-symbols-rounded text-sm">arrow_back</span>
        Retour à la liste
    </a>
    <h1 class="text-3xl font-bold text-base-content">Profil Médecin</h1>
    <p class="text-sm text-base-content/70 mt-1">Dossier complet pour vérification</p>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Main Info -->
    <div class="card bg-base-100 shadow-sm border border-base-200 lg:col-span-2">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-success">badge</span>
                Informations Professionnelles
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Nom Complet</label>
                    <p class="text-lg font-semibold">Dr. {{ e($doctor->user?->first_name ?? '—') }} {{ e($doctor->user?->last_name ?? '') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Email</label>
                    <p class="text-lg">{{ e($doctor->user?->email ?? '—') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">N° RPPS</label>
                    <p class="font-mono text-lg font-bold text-primary">{{ e($doctor->rpps ?? '—') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Spécialité</label>
                    <p class="text-lg">{{ e($doctor->specialty ?? '—') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Ville</label>
                    <p class="text-lg">{{ e($doctor->city ?? '—') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Adresse</label>
                    <p class="text-lg">{{ e($doctor->address ?? '—') }}</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Tarif Consultation</label>
                    <p class="text-lg font-bold text-success">{{ $doctor->consultation_fee ?? '—' }} €</p>
                </div>
                <div>
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Vidéo Consultation</label>
                    @if($doctor->is_available_for_video)
                        <span class="badge badge-success gap-1 mt-1">
                            <span class="material-symbols-rounded text-xs">videocam</span> Disponible
                        </span>
                    @else
                        <span class="badge badge-ghost gap-1 mt-1">
                            <span class="material-symbols-rounded text-xs">videocam_off</span> Non disponible
                        </span>
                    @endif
                </div>
            </div>

            @if($doctor->bio)
                <div class="mt-4">
                    <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Biographie</label>
                    <p class="text-sm mt-1 p-3 bg-base-200 rounded-lg">{{ e($doctor->bio) }}</p>
                </div>
            @endif

            <div class="mt-4">
                <label class="text-xs font-bold text-gray-400 uppercase tracking-wider">Note</label>
                <div class="flex items-center gap-2 mt-1">
                    @for($i = 1; $i <= 5; $i++)
                        <span class="material-symbols-rounded text-lg {{ $i <= ($doctor->rating ?? 0) ? 'text-warning' : 'text-gray-300' }}">star</span>
                    @endfor
                    <span class="font-bold ml-1">{{ $doctor->rating ?? '0.0' }}</span>
                    <span class="text-xs text-gray-400">({{ $doctor->total_reviews ?? 0 }} avis)</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Side Panel -->
    <div class="space-y-6">
        <!-- Schedule -->
        @if($doctor->schedules && $doctor->schedules->count())
            <div class="card bg-base-100 shadow-sm border border-base-200">
                <div class="card-body">
                    <h3 class="card-title text-md font-bold">
                        <span class="material-symbols-rounded text-primary">schedule</span>
                        Planning
                    </h3>
                    <div class="space-y-2 mt-2">
                        @foreach($doctor->schedules as $schedule)
                            <div class="flex items-center justify-between p-2 bg-base-200/50 rounded-lg text-sm">
                                <span class="font-medium">{{ e($schedule->day_of_week ?? '') }}</span>
                                <span class="text-xs text-gray-400">
                                    {{ $schedule->start_time ?? '' }} - {{ $schedule->end_time ?? '' }}
                                </span>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>
        @endif

        <!-- Geolocation -->
        @if($doctor->latitude && $doctor->longitude)
            <div class="card bg-base-100 shadow-sm border border-base-200">
                <div class="card-body">
                    <h3 class="card-title text-md font-bold">
                        <span class="material-symbols-rounded text-info">location_on</span>
                        Géolocalisation
                    </h3>
                    <div class="text-xs font-mono mt-2 bg-base-200 p-2 rounded">
                        Lat: {{ $doctor->latitude }}<br>
                        Lng: {{ $doctor->longitude }}
                    </div>
                </div>
            </div>
        @endif

        <!-- Actions -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body">
                <h3 class="card-title text-md font-bold">
                    <span class="material-symbols-rounded text-warning">bolt</span>
                    Actions
                </h3>
                <div class="space-y-2 mt-2">
                    <a href="{{ route('admin.users.show', $doctor->user_id) }}" class="btn btn-outline btn-sm w-full justify-start gap-2">
                        <span class="material-symbols-rounded text-sm">person</span>
                        Voir le profil utilisateur
                    </a>
                    <a href="{{ route('admin.appointments.index', ['search' => $doctor->user?->email]) }}" class="btn btn-outline btn-sm w-full justify-start gap-2">
                        <span class="material-symbols-rounded text-sm">event</span>
                        Voir les rendez-vous
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
