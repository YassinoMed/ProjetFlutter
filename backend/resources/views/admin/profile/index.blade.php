@extends('admin.layouts.app')

@section('content')
<div class="mb-6">
    <h1 class="text-3xl font-bold text-base-content">Mon Profil</h1>
    <p class="text-sm text-base-content/70 mt-1">Gérer vos informations et votre mot de passe</p>
</div>

@if(session('success'))
    <div class="alert alert-success shadow-sm mb-6">
        <span class="material-symbols-rounded">check_circle</span>
        <span>{{ session('success') }}</span>
    </div>
@endif

<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Profile Info -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-primary">person</span>
                Informations Personnelles
            </h2>

            <form method="POST" action="{{ route('admin.profile.update') }}">
                @csrf
                @method('PUT')

                <div class="form-control mb-4">
                    <label class="label"><span class="label-text font-medium">Prénom</span></label>
                    <input type="text" name="first_name" value="{{ old('first_name', $admin->first_name) }}" required
                           class="input input-bordered w-full @error('first_name') input-error @enderror" maxlength="100" />
                    @error('first_name')
                        <label class="label"><span class="label-text-alt text-error">{{ $message }}</span></label>
                    @enderror
                </div>

                <div class="form-control mb-4">
                    <label class="label"><span class="label-text font-medium">Nom</span></label>
                    <input type="text" name="last_name" value="{{ old('last_name', $admin->last_name) }}" required
                           class="input input-bordered w-full @error('last_name') input-error @enderror" maxlength="100" />
                    @error('last_name')
                        <label class="label"><span class="label-text-alt text-error">{{ $message }}</span></label>
                    @enderror
                </div>

                <div class="form-control mb-4">
                    <label class="label"><span class="label-text font-medium">Email</span></label>
                    <input type="email" value="{{ $admin->email }}" disabled
                           class="input input-bordered w-full opacity-50" />
                    <label class="label"><span class="label-text-alt text-gray-400">L'email ne peut pas être modifié</span></label>
                </div>

                <div class="form-control mb-4">
                    <label class="label"><span class="label-text font-medium">Téléphone</span></label>
                    <input type="text" name="phone" value="{{ old('phone', $admin->phone) }}"
                           class="input input-bordered w-full @error('phone') input-error @enderror" maxlength="20" />
                    @error('phone')
                        <label class="label"><span class="label-text-alt text-error">{{ $message }}</span></label>
                    @enderror
                </div>

                <button type="submit" class="btn btn-primary w-full gap-2">
                    <span class="material-symbols-rounded text-sm">save</span>
                    Enregistrer
                </button>
            </form>
        </div>
    </div>

    <!-- Change Password -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-warning">lock</span>
                Changer le Mot de Passe
            </h2>

            <form method="POST" action="{{ route('admin.profile.password') }}">
                @csrf
                @method('PUT')

                <div class="form-control mb-4">
                    <label class="label"><span class="label-text font-medium">Mot de passe actuel</span></label>
                    <input type="password" name="current_password" required
                           class="input input-bordered w-full @error('current_password') input-error @enderror"
                           autocomplete="current-password" />
                    @error('current_password')
                        <label class="label"><span class="label-text-alt text-error">{{ $message }}</span></label>
                    @enderror
                </div>

                <div class="form-control mb-4">
                    <label class="label"><span class="label-text font-medium">Nouveau mot de passe</span></label>
                    <input type="password" name="password" required
                           class="input input-bordered w-full @error('password') input-error @enderror"
                           autocomplete="new-password" minlength="8" />
                    @error('password')
                        <label class="label"><span class="label-text-alt text-error">{{ $message }}</span></label>
                    @enderror
                    <label class="label"><span class="label-text-alt text-gray-400">Min. 8 caractères, majuscule, chiffre et symbole</span></label>
                </div>

                <div class="form-control mb-6">
                    <label class="label"><span class="label-text font-medium">Confirmer le mot de passe</span></label>
                    <input type="password" name="password_confirmation" required
                           class="input input-bordered w-full"
                           autocomplete="new-password" minlength="8" />
                </div>

                <button type="submit" class="btn btn-warning w-full gap-2">
                    <span class="material-symbols-rounded text-sm">key</span>
                    Modifier le mot de passe
                </button>
            </form>

            <!-- Security Info -->
            <div class="mt-6 p-3 bg-base-200/50 rounded-lg">
                <h4 class="font-bold text-xs text-gray-400 uppercase mb-2">Politique de mot de passe</h4>
                <ul class="text-xs text-gray-500 space-y-1">
                    <li class="flex items-center gap-1">
                        <span class="material-symbols-rounded text-xs text-success">check</span>
                        Minimum 8 caractères
                    </li>
                    <li class="flex items-center gap-1">
                        <span class="material-symbols-rounded text-xs text-success">check</span>
                        Au moins une majuscule et une minuscule
                    </li>
                    <li class="flex items-center gap-1">
                        <span class="material-symbols-rounded text-xs text-success">check</span>
                        Au moins un chiffre
                    </li>
                    <li class="flex items-center gap-1">
                        <span class="material-symbols-rounded text-xs text-success">check</span>
                        Au moins un symbole (@, #, $, etc.)
                    </li>
                </ul>
            </div>
        </div>
    </div>
</div>
@endsection
