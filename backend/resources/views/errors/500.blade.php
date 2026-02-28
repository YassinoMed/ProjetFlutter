@extends('admin.layouts.app')

@section('content')
<div class="flex flex-col items-center justify-center min-h-[60vh] text-center">
    <div class="bg-error/10 p-6 rounded-full mb-6">
        <span class="material-symbols-rounded text-6xl text-error">error</span>
    </div>
    <h1 class="text-6xl font-bold text-error mb-2">500</h1>
    <h2 class="text-2xl font-bold text-base-content mb-2">Erreur Serveur</h2>
    <p class="text-base-content/60 max-w-md mb-8">
        Une erreur interne est survenue. Notre équipe a été notifiée. Veuillez réessayer ultérieurement.
    </p>
    <div class="flex gap-3">
        <a href="{{ route('admin.dashboard') }}" class="btn btn-primary gap-2">
            <span class="material-symbols-rounded text-sm">home</span>
            Tableau de bord
        </a>
        <button onclick="location.reload()" class="btn btn-ghost gap-2">
            <span class="material-symbols-rounded text-sm">refresh</span>
            Réessayer
        </button>
    </div>
</div>
@endsection
