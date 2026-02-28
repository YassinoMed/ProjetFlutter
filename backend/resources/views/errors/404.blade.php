@extends('admin.layouts.app')

@section('content')
<div class="flex flex-col items-center justify-center min-h-[60vh] text-center">
    <div class="bg-warning/10 p-6 rounded-full mb-6">
        <span class="material-symbols-rounded text-6xl text-warning">search_off</span>
    </div>
    <h1 class="text-6xl font-bold text-warning mb-2">404</h1>
    <h2 class="text-2xl font-bold text-base-content mb-2">Page Non Trouvée</h2>
    <p class="text-base-content/60 max-w-md mb-8">
        La page demandée n'existe pas ou a été déplacée. Vérifiez l'URL ou retournez au tableau de bord.
    </p>
    <div class="flex gap-3">
        <a href="{{ route('admin.dashboard') }}" class="btn btn-primary gap-2">
            <span class="material-symbols-rounded text-sm">home</span>
            Tableau de bord
        </a>
        <a href="javascript:history.back()" class="btn btn-ghost gap-2">
            <span class="material-symbols-rounded text-sm">arrow_back</span>
            Retour
        </a>
    </div>
</div>
@endsection
