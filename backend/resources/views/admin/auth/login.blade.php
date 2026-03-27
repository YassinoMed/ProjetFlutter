@extends('admin.layouts.app')

@section('page-title', 'Connexion administrateur')

@section('content')
<div class="mx-auto w-full max-w-6xl">
    <div class="grid overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950/85 shadow-[0_40px_120px_-55px_rgba(15,23,42,0.95)] lg:grid-cols-[1.08fr_0.92fr]">
        <section class="relative hidden overflow-hidden lg:flex flex-col justify-between px-10 py-10 text-white">
            <div class="absolute inset-0 bg-[radial-gradient(circle_at_top_left,_rgba(14,165,233,0.26),_transparent_34%),radial-gradient(circle_at_bottom_right,_rgba(16,185,129,0.18),_transparent_22%)]"></div>
            <div class="relative z-10">
                <div class="inline-flex h-16 w-16 items-center justify-center rounded-[1.4rem] border border-white/10 bg-white/8 text-2xl font-extrabold tracking-tight shadow-2xl shadow-sky-950/30">
                    M+
                </div>

                <div class="mt-10 max-w-md">
                    <p class="text-xs font-bold uppercase tracking-[0.35em] text-sky-200/80">Console administration</p>
                    <h1 class="mt-4 text-5xl font-black leading-[1.02] tracking-[-0.04em]">
                        Administrez MediConnect avec plus de clarte.
                    </h1>
                    <p class="mt-5 text-base leading-7 text-slate-200/80">
                        Acces centralise aux comptes, validations medecins, audit, RGPD, rendez-vous et supervision des flux de communication.
                    </p>
                </div>
            </div>

            <div class="relative z-10 grid gap-4 sm:grid-cols-3">
                <div class="rounded-[1.4rem] border border-white/10 bg-white/6 p-4 backdrop-blur">
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-sky-200/75">Securite</div>
                    <div class="mt-2 text-2xl font-extrabold">E2E</div>
                    <div class="mt-1 text-sm text-slate-300/70">Messagerie protegee</div>
                </div>
                <div class="rounded-[1.4rem] border border-white/10 bg-white/6 p-4 backdrop-blur">
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-emerald-200/75">Conformite</div>
                    <div class="mt-2 text-2xl font-extrabold">RGPD</div>
                    <div class="mt-1 text-sm text-slate-300/70">Traites et traces</div>
                </div>
                <div class="rounded-[1.4rem] border border-white/10 bg-white/6 p-4 backdrop-blur">
                    <div class="text-xs font-bold uppercase tracking-[0.18em] text-violet-200/75">Pilotage</div>
                    <div class="mt-2 text-2xl font-extrabold">360</div>
                    <div class="mt-1 text-sm text-slate-300/70">Vue back-office</div>
                </div>
            </div>
        </section>

        <section class="bg-white/96 px-6 py-8 sm:px-10 sm:py-10">
            <div class="mx-auto max-w-md">
                <div class="mb-8">
                    <div class="inline-flex items-center gap-2 rounded-full bg-blue-50 px-4 py-2 text-xs font-bold uppercase tracking-[0.18em] text-blue-700">
                        <i class="ti ti-shield-lock"></i>
                        Connexion securisee
                    </div>
                    <h2 class="mt-5 text-4xl font-black tracking-[-0.04em] text-slate-950">Bienvenue</h2>
                    <p class="mt-3 text-sm leading-6 text-slate-500">
                        Connectez-vous pour administrer l'espace medical, suivre les operations sensibles et piloter la plateforme.
                    </p>
                </div>

                @if($errors->any())
                    <div class="alert alert-error mb-5 flex items-start gap-3">
                        <i class="ti ti-alert-circle text-lg"></i>
                        <span class="text-sm font-semibold">{{ $errors->first() }}</span>
                    </div>
                @endif

                @if(session('error'))
                    <div class="alert alert-error mb-5 flex items-start gap-3">
                        <i class="ti ti-alert-triangle text-lg"></i>
                        <span class="text-sm font-semibold">{{ session('error') }}</span>
                    </div>
                @endif

                <form method="POST" action="{{ route('admin.login.post') }}" autocomplete="off" class="space-y-5">
                    @csrf

                    <div style="position: absolute; left: -9999px;" aria-hidden="true">
                        <label for="website_url">Ne pas remplir</label>
                        <input type="text" name="website_url" id="website_url" tabindex="-1" autocomplete="off" />
                    </div>

                    <div class="space-y-2">
                        <label for="email" class="block text-sm font-bold text-slate-700">Email administrateur</label>
                        <div class="relative">
                            <i class="ti ti-mail absolute left-4 top-1/2 -translate-y-1/2 text-lg text-slate-400"></i>
                            <input
                                id="email"
                                type="email"
                                name="email"
                                value="{{ old('email') }}"
                                required
                                autofocus
                                maxlength="255"
                                autocomplete="email"
                                class="input h-14 w-full pl-12"
                                placeholder="admin@mediconnect.pro"
                            />
                        </div>
                    </div>

                    <div class="space-y-2">
                        <div class="flex items-center justify-between gap-3">
                            <label for="password" class="block text-sm font-bold text-slate-700">Mot de passe</label>
                            <span class="text-xs font-semibold text-slate-400">Minimum 8 caracteres</span>
                        </div>
                        <div class="relative">
                            <i class="ti ti-lock absolute left-4 top-1/2 -translate-y-1/2 text-lg text-slate-400"></i>
                            <input
                                id="password"
                                type="password"
                                name="password"
                                required
                                minlength="8"
                                maxlength="255"
                                autocomplete="current-password"
                                class="input h-14 w-full pl-12"
                                placeholder="••••••••"
                            />
                        </div>
                    </div>

                    <button type="submit" class="btn btn-primary h-14 w-full text-base">
                        <i class="ti ti-login-2 text-lg"></i>
                        Acceder au back-office
                    </button>
                </form>

                <div class="mt-8 grid gap-3 sm:grid-cols-2">
                    <div class="rounded-[1.25rem] border border-slate-200 bg-slate-50 p-4">
                        <div class="flex items-center gap-2 text-sm font-bold text-slate-800">
                            <i class="ti ti-device-laptop text-blue-600"></i>
                            Session protegee
                        </div>
                        <p class="mt-2 text-xs leading-5 text-slate-500">
                            Protection CSRF, verification serveur et journalisation des actions sensibles.
                        </p>
                    </div>

                    <div class="rounded-[1.25rem] border border-emerald-200 bg-emerald-50/70 p-4">
                        <div class="flex items-center gap-2 text-sm font-bold text-emerald-700">
                            <i class="ti ti-lock-check"></i>
                            Chiffrement actif
                        </div>
                        <p class="mt-2 text-xs leading-5 text-emerald-700/70">
                            Les flux critiques et les donnees de sante restent traites dans un cadre securise.
                        </p>
                    </div>
                </div>
            </div>
        </section>
    </div>
</div>
@endsection
