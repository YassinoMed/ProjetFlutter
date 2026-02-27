@extends('admin.layouts.app')

@section('content')
<div class="card w-full max-w-sm shadow-2xl bg-base-100 mx-auto">
    <div class="card-body">
        <h2 class="card-title justify-center text-primary mb-6 text-2xl font-bold">
            <span class="material-symbols-rounded">medical_services</span>
            Admin Login
        </h2>

        @if($errors->any())
            <div class="alert alert-error text-sm p-3 rounded-xl">
                <span class="material-symbols-rounded">error</span>
                <span>{{ $errors->first() }}</span>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.login.post') }}">
            @csrf

            <div class="form-control mb-4">
                <label class="label"><span class="label-text font-medium">Email Admin</span></label>
                <input type="email" name="email" value="{{ old('email') }}" required autofocus
                       class="input input-bordered w-full" placeholder="admin@mediconnect.pro" />
            </div>

            <div class="form-control mb-6">
                <label class="label"><span class="label-text font-medium">Mot de passe</span></label>
                <input type="password" name="password" required 
                       class="input input-bordered w-full" placeholder="••••••••" />
            </div>

            <div class="form-control mt-6">
                <button type="submit" class="btn btn-primary w-full text-white text-lg rounded-xl">
                    Connexion Sécurisée
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
