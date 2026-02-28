@extends('admin.layouts.app')

@section('content')
<div class="card w-full max-w-md shadow-2xl bg-base-100 mx-auto">
    <div class="card-body">
        <!-- Logo & Title -->
        <div class="text-center mb-6">
            <div class="inline-flex items-center justify-center bg-primary text-primary-content p-3 rounded-xl mb-3">
                <span class="material-symbols-rounded text-3xl">health_and_safety</span>
            </div>
            <h2 class="text-2xl font-bold text-primary">MediConnect Pro</h2>
            <p class="text-sm text-gray-400 mt-1">Connexion Administrateur Sécurisée</p>
        </div>

        <!-- Error Messages -->
        @if($errors->any())
            <div class="alert alert-error text-sm p-3 rounded-xl mb-4">
                <span class="material-symbols-rounded">error</span>
                <span>{{ $errors->first() }}</span>
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-warning text-sm p-3 rounded-xl mb-4">
                <span class="material-symbols-rounded">warning</span>
                <span>{{ session('error') }}</span>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.login.post') }}" autocomplete="off">
            @csrf

            <!-- Honeypot field (hidden anti-bot trap) -->
            <div style="position: absolute; left: -9999px;" aria-hidden="true">
                <label for="website_url">Ne pas remplir</label>
                <input type="text" name="website_url" id="website_url" tabindex="-1" autocomplete="off" />
            </div>

            <div class="form-control mb-4">
                <label class="label">
                    <span class="label-text font-medium">
                        <span class="material-symbols-rounded text-sm align-middle mr-1">email</span>
                        Email Admin
                    </span>
                </label>
                <input type="email" name="email" value="{{ old('email') }}" required autofocus
                       class="input input-bordered w-full focus:input-primary"
                       placeholder="admin@mediconnect.pro"
                       maxlength="255"
                       autocomplete="email" />
            </div>

            <div class="form-control mb-6">
                <label class="label">
                    <span class="label-text font-medium">
                        <span class="material-symbols-rounded text-sm align-middle mr-1">lock</span>
                        Mot de passe
                    </span>
                </label>
                <input type="password" name="password" required
                       class="input input-bordered w-full focus:input-primary"
                       placeholder="••••••••"
                       minlength="8"
                       maxlength="255"
                       autocomplete="current-password" />
            </div>

            <div class="form-control mt-6">
                <button type="submit" class="btn btn-primary w-full text-white text-lg rounded-xl gap-2">
                    <span class="material-symbols-rounded">login</span>
                    Connexion Sécurisée
                </button>
            </div>
        </form>

        <!-- Security Badge -->
        <div class="mt-6 text-center">
            <div class="inline-flex items-center gap-1 text-xs text-gray-400 bg-base-200 px-3 py-1.5 rounded-full">
                <span class="material-symbols-rounded text-xs text-success">verified_user</span>
                Connexion protégée – HTTPS & CSRF
            </div>
        </div>
    </div>
</div>
@endsection
