<!DOCTYPE html>
<html lang="fr" data-theme="corporate">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    @php($pageTitle = trim($__env->yieldContent('page-title')) ?: 'Administration')

    <title>{{ $pageTitle }} | MediConnect Pro</title>

    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.10.1/dist/full.min.css" rel="stylesheet" type="text/css" />
    <script src="https://cdn.tailwindcss.com"></script>

    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.8/dist/cdn.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@2.46.0/tabler-icons.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,500,0,0&display=swap" rel="stylesheet">

    <style>
        :root {
            --admin-bg: #eff5fb;
            --admin-bg-accent: #dce9fb;
            --admin-surface: rgba(255, 255, 255, 0.86);
            --admin-surface-strong: rgba(255, 255, 255, 0.96);
            --admin-border: rgba(148, 163, 184, 0.18);
            --admin-border-strong: rgba(148, 163, 184, 0.3);
            --admin-text: #0f172a;
            --admin-muted: #64748b;
            --admin-primary: #0b63ce;
            --admin-primary-dark: #004e99;
            --admin-primary-soft: #e7f0ff;
            --admin-success: #0f9f64;
            --admin-success-soft: #e6faf1;
            --admin-warning: #d97706;
            --admin-warning-soft: #fff6dd;
            --admin-danger: #dc2626;
            --admin-danger-soft: #ffe8e8;
            --admin-shadow: 0 24px 80px -40px rgba(15, 23, 42, 0.32);
            --admin-shadow-soft: 0 18px 44px -28px rgba(15, 23, 42, 0.22);
            --admin-sidebar: linear-gradient(180deg, #071126 0%, #0b1734 48%, #101f46 100%);
        }

        * {
            scrollbar-width: thin;
            scrollbar-color: rgba(148, 163, 184, 0.55) transparent;
        }

        *::-webkit-scrollbar {
            width: 10px;
            height: 10px;
        }

        *::-webkit-scrollbar-thumb {
            background: rgba(148, 163, 184, 0.55);
            border-radius: 999px;
        }

        *::-webkit-scrollbar-track {
            background: transparent;
        }

        html, body {
            min-height: 100%;
        }

        body {
            font-family: 'Inter', system-ui, sans-serif;
            color: var(--admin-text);
            background:
                radial-gradient(circle at top left, rgba(11, 99, 206, 0.16), transparent 32%),
                radial-gradient(circle at bottom right, rgba(15, 159, 100, 0.12), transparent 22%),
                linear-gradient(180deg, #f7fbff 0%, var(--admin-bg) 100%);
        }

        .material-symbols-rounded {
            font-variation-settings: 'FILL' 0, 'wght' 500, 'GRAD' 0, 'opsz' 24;
            vertical-align: middle;
        }

        .admin-shell {
            min-height: 100vh;
            width: 100%;
        }

        .admin-main {
            background: transparent;
        }

        .glass-nav {
            position: sticky;
            top: 0;
            z-index: 50;
            background: rgba(247, 251, 255, 0.84);
            border-bottom: 1px solid rgba(255, 255, 255, 0.8);
            box-shadow: 0 12px 30px -24px rgba(15, 23, 42, 0.28);
            backdrop-filter: blur(22px);
        }

        .topbar-shell {
            width: min(1480px, 100%);
            margin: 0 auto;
            padding: 1.15rem 1.5rem;
        }

        .page-shell {
            width: min(1480px, 100%);
            margin: 0 auto;
            padding: 2rem 1.5rem 3rem;
        }

        .page-card,
        .card,
        .modal-box,
        .dropdown-content {
            border: 1px solid var(--admin-border);
            border-radius: 28px;
            background: var(--admin-surface);
            box-shadow: var(--admin-shadow-soft);
            backdrop-filter: blur(14px);
        }

        .card {
            overflow: hidden;
        }

        .card-body {
            padding: 1.5rem;
        }

        .card-lift,
        .card,
        .btn,
        .menu li > a {
            transition: transform 180ms ease, box-shadow 180ms ease, background-color 180ms ease, border-color 180ms ease, color 180ms ease;
        }

        .card-lift:hover,
        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 26px 54px -34px rgba(15, 23, 42, 0.32);
        }

        .sidebar-shell {
            border-right: 1px solid rgba(255, 255, 255, 0.06);
            box-shadow: 28px 0 60px -38px rgba(3, 7, 18, 0.66);
        }

        .sidebar-panel {
            position: relative;
            overflow: hidden;
            background: var(--admin-sidebar);
            color: #d8e4ff;
        }

        .sidebar-panel::before,
        .sidebar-panel::after {
            content: '';
            position: absolute;
            border-radius: 999px;
            filter: blur(18px);
            opacity: 0.58;
            pointer-events: none;
        }

        .sidebar-panel::before {
            top: -80px;
            right: -120px;
            width: 240px;
            height: 240px;
            background: rgba(59, 130, 246, 0.26);
        }

        .sidebar-panel::after {
            bottom: 80px;
            left: -120px;
            width: 220px;
            height: 220px;
            background: rgba(16, 185, 129, 0.15);
        }

        .brand-mark {
            width: 3.5rem;
            height: 3.5rem;
            border-radius: 1.35rem;
            display: grid;
            place-items: center;
            background: linear-gradient(145deg, rgba(56, 189, 248, 0.28), rgba(11, 99, 206, 0.8));
            border: 1px solid rgba(191, 219, 254, 0.24);
            box-shadow: 0 22px 38px -28px rgba(56, 189, 248, 0.72);
            color: white;
        }

        .section-label {
            margin: 2rem 0 0.75rem;
            padding: 0 0.95rem;
            font-size: 0.68rem;
            font-weight: 700;
            letter-spacing: 0.16em;
            text-transform: uppercase;
            color: rgba(191, 219, 254, 0.58);
        }

        .menu li > a {
            min-height: 3.25rem;
            border-radius: 1rem;
            padding: 0.95rem 1rem;
            font-weight: 600;
            color: rgba(226, 232, 240, 0.8);
            gap: 0.875rem;
        }

        .menu li > a:hover {
            transform: translateX(2px);
            background: rgba(255, 255, 255, 0.08);
            color: #ffffff;
        }

        .menu li > a.active {
            background: linear-gradient(135deg, rgba(59, 130, 246, 0.24), rgba(14, 116, 144, 0.18));
            color: #ffffff;
            border: 1px solid rgba(191, 219, 254, 0.16);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
        }

        .menu li > a .ti,
        .menu li > a .material-symbols-rounded {
            font-size: 1.25rem;
        }

        .btn {
            min-height: 2.9rem;
            border-radius: 1rem;
            font-weight: 700;
            letter-spacing: -0.01em;
            border-color: transparent;
            text-transform: none;
        }

        .btn:hover {
            transform: translateY(-1px);
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--admin-primary) 0%, var(--admin-primary-dark) 100%);
            color: #fff;
            box-shadow: 0 20px 40px -24px rgba(11, 99, 206, 0.72);
        }

        .btn-primary:hover {
            filter: brightness(1.02);
        }

        .btn-ghost,
        .btn-outline {
            background: rgba(255, 255, 255, 0.7);
            color: var(--admin-text);
            border: 1px solid var(--admin-border-strong);
        }

        .btn-ghost:hover,
        .btn-outline:hover {
            background: rgba(255, 255, 255, 0.92);
            border-color: rgba(11, 99, 206, 0.2);
        }

        .btn-error {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
            color: white;
        }

        .input,
        .select,
        .textarea {
            border-radius: 1rem;
            border: 1px solid var(--admin-border-strong);
            background: #f8fbff;
            color: var(--admin-text);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.7);
        }

        .input::placeholder,
        .textarea::placeholder {
            color: #94a3b8;
        }

        .input:focus,
        .select:focus,
        .textarea:focus {
            outline: none;
            border-color: rgba(11, 99, 206, 0.38);
            box-shadow: 0 0 0 4px rgba(11, 99, 206, 0.1);
        }

        .table thead th {
            background: rgba(241, 245, 249, 0.72);
            color: var(--admin-muted);
            font-size: 0.75rem;
            font-weight: 800;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            padding-top: 1rem;
            padding-bottom: 1rem;
        }

        .table tbody td {
            padding-top: 1rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid rgba(226, 232, 240, 0.72);
        }

        .table tbody tr:last-child td {
            border-bottom: none;
        }

        .table.table-zebra tbody tr:nth-child(even) {
            background: rgba(248, 250, 252, 0.74);
        }

        .table tbody tr:hover {
            background: rgba(236, 244, 255, 0.88);
        }

        .badge {
            min-height: 1.95rem;
            border-radius: 999px;
            padding: 0.4rem 0.8rem;
            border: none;
            font-weight: 700;
            gap: 0.4rem;
        }

        .badge-info {
            background: #e8f1ff;
            color: #0b63ce;
        }

        .badge-success {
            background: #e7faf1;
            color: #0f9f64;
        }

        .badge-warning {
            background: #fff4d4;
            color: #b7791f;
        }

        .badge-error {
            background: #ffe8e8;
            color: #d92d20;
        }

        .badge-ghost {
            background: #eef2f7;
            color: #475569;
        }

        .alert {
            position: relative;
            border-radius: 1.25rem;
            border: 1px solid rgba(255, 255, 255, 0.65);
            box-shadow: var(--admin-shadow-soft);
        }

        .alert-success {
            background: linear-gradient(135deg, rgba(15, 159, 100, 0.14), rgba(230, 250, 241, 0.92));
            color: #065f46;
        }

        .alert-error {
            background: linear-gradient(135deg, rgba(220, 38, 38, 0.14), rgba(255, 236, 236, 0.96));
            color: #991b1b;
        }

        .divider::before,
        .divider::after {
            background-color: rgba(148, 163, 184, 0.16);
        }

        .auth-canvas {
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 2rem;
            background:
                radial-gradient(circle at top left, rgba(14, 116, 144, 0.18), transparent 26%),
                radial-gradient(circle at bottom right, rgba(16, 185, 129, 0.12), transparent 24%),
                linear-gradient(135deg, #050b19 0%, #0c1630 46%, #112048 100%);
        }

        .auth-container {
            width: min(1180px, 100%);
        }

        .pill {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            border-radius: 999px;
            padding: 0.5rem 0.85rem;
            font-size: 0.75rem;
            font-weight: 700;
            letter-spacing: 0.04em;
        }

        .pill-primary {
            background: rgba(11, 99, 206, 0.12);
            color: var(--admin-primary-dark);
            border: 1px solid rgba(11, 99, 206, 0.12);
        }

        .pill-success {
            background: rgba(15, 159, 100, 0.14);
            color: #047857;
            border: 1px solid rgba(15, 159, 100, 0.12);
        }

        .metric-card {
            position: relative;
            overflow: hidden;
            border-radius: 1.6rem;
            border: 1px solid var(--admin-border);
            background: linear-gradient(180deg, rgba(255, 255, 255, 0.96), rgba(248, 251, 255, 0.9));
            box-shadow: var(--admin-shadow-soft);
        }

        .metric-card::after {
            content: '';
            position: absolute;
            inset: auto -24px -28px auto;
            width: 140px;
            height: 140px;
            border-radius: 999px;
            opacity: 0.12;
            background: currentColor;
            filter: blur(10px);
        }

        .table-shell,
        .filter-shell {
            overflow: hidden;
            border-radius: 1.75rem;
            border: 1px solid var(--admin-border);
            background: var(--admin-surface-strong);
            box-shadow: var(--admin-shadow-soft);
        }

        [aria-label="Pagination Navigation"] {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
        }

        [aria-label="Pagination Navigation"] > div:first-child {
            font-size: 0.875rem;
            color: var(--admin-muted);
        }

        [aria-label="Pagination Navigation"] > div:last-child > span,
        [aria-label="Pagination Navigation"] a,
        [aria-label="Pagination Navigation"] span[aria-current="page"] {
            border-radius: 0.9rem !important;
            border: 1px solid var(--admin-border-strong);
            background: white;
            color: var(--admin-text);
            box-shadow: none !important;
        }

        [aria-label="Pagination Navigation"] span[aria-current="page"] {
            background: linear-gradient(135deg, var(--admin-primary) 0%, var(--admin-primary-dark) 100%);
            color: white;
            border-color: transparent;
        }

        @media (max-width: 1023px) {
            .topbar-shell,
            .page-shell {
                padding-left: 1rem;
                padding-right: 1rem;
            }
        }
    </style>

    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        medical: {
                            50: '#eff8ff',
                            100: '#dcecff',
                            500: '#0b63ce',
                            600: '#004e99',
                            900: '#08152f',
                        }
                    }
                }
            }
        }
    </script>

    @stack('styles')
    @livewireStyles
</head>
<body>
    @auth('web')
        @php($currentUser = auth()->user())

        <div class="drawer lg:drawer-open admin-shell">
            <input id="admin-drawer" type="checkbox" class="drawer-toggle" />

            <div class="drawer-content admin-main flex min-h-screen flex-col">
                <header class="glass-nav">
                    <div class="topbar-shell">
                        <div class="navbar min-h-0 gap-4 px-0">
                            <div class="flex items-center gap-3">
                                <div class="flex-none lg:hidden">
                                    <label for="admin-drawer" class="btn btn-ghost btn-circle">
                                        <i class="ti ti-menu-2 text-xl"></i>
                                    </label>
                                </div>

                                <div class="hidden lg:block">
                                    <p class="text-[11px] font-bold uppercase tracking-[0.24em] text-slate-400">MediConnect Pro</p>
                                    <h1 class="text-lg font-extrabold tracking-tight text-slate-900">{{ $pageTitle }}</h1>
                                </div>
                            </div>

                            <div class="ml-auto flex items-center gap-3">
                                <div class="hidden md:flex items-center gap-2 rounded-full border border-white/80 bg-white/70 px-3 py-2 text-xs font-semibold text-slate-500 shadow-sm">
                                    <i class="ti ti-shield-lock text-sm text-emerald-600"></i>
                                    Supervision securisee
                                </div>

                                <div class="hidden xl:flex items-center gap-2 rounded-full border border-white/80 bg-white/70 px-3 py-2 text-xs font-semibold text-slate-500 shadow-sm">
                                    <i class="ti ti-calendar-event text-sm text-sky-600"></i>
                                    {{ now()->format('d/m/Y') }}
                                </div>

                                <div class="dropdown dropdown-end">
                                    <div tabindex="0" role="button" class="btn btn-ghost btn-circle border border-white/80 bg-white/80 shadow-sm">
                                        <div class="indicator">
                                            <i class="ti ti-bell text-xl text-slate-700"></i>
                                            <span class="badge badge-error badge-xs indicator-item"></span>
                                        </div>
                                    </div>
                                </div>

                                <div class="dropdown dropdown-end">
                                    <div tabindex="0" role="button" class="flex items-center gap-3 rounded-full border border-white/80 bg-white/78 px-2 py-2 shadow-sm">
                                        <div class="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-blue-600 to-sky-400 text-sm font-extrabold text-white shadow-lg shadow-blue-200/70">
                                            {{ strtoupper(substr($currentUser->first_name ?? 'A', 0, 1)) }}
                                        </div>
                                        <div class="hidden pr-3 text-left md:block">
                                            <div class="text-sm font-bold text-slate-900">
                                                {{ $currentUser->first_name ?? 'Admin' }} {{ $currentUser->last_name ?? '' }}
                                            </div>
                                            <div class="text-xs font-medium text-slate-500">{{ $currentUser->email ?? '' }}</div>
                                        </div>
                                    </div>

                                    <ul tabindex="0" class="dropdown-content z-[1] mt-4 w-64 p-2">
                                        <li class="rounded-2xl border border-slate-100 bg-white/95 p-4">
                                            <div class="flex flex-col gap-1">
                                                <span class="text-xs font-bold uppercase tracking-[0.2em] text-slate-400">Session admin</span>
                                                <span class="text-base font-extrabold text-slate-900">
                                                    {{ $currentUser->first_name ?? 'Admin' }} {{ $currentUser->last_name ?? '' }}
                                                </span>
                                                <span class="text-xs font-medium text-slate-500">{{ $currentUser->email ?? '' }}</span>
                                            </div>
                                        </li>
                                        <li class="mt-2">
                                            <a href="{{ route('admin.profile.index') }}">
                                                <i class="ti ti-user-cog"></i>
                                                Mon profil
                                            </a>
                                        </li>
                                        <li>
                                            <a href="{{ route('admin.settings.index') }}">
                                                <i class="ti ti-settings"></i>
                                                Parametres
                                            </a>
                                        </li>
                                        <li class="mt-1">
                                            <form method="POST" action="{{ route('admin.logout') }}" class="w-full">
                                                @csrf
                                                <button type="submit" class="btn btn-ghost w-full justify-start text-red-600 hover:bg-red-50 hover:text-red-700">
                                                    <i class="ti ti-logout"></i>
                                                    Deconnexion
                                                </button>
                                            </form>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </header>

                <main class="page-shell">
                    @if(session('success'))
                        <div x-data="{ show: true }" x-show="show" class="alert alert-success mb-6">
                            <i class="ti ti-circle-check text-xl"></i>
                            <span class="font-semibold">{{ session('success') }}</span>
                            <button @click="show = false" class="btn btn-ghost btn-sm btn-circle absolute right-3 top-3">
                                <i class="ti ti-x text-sm"></i>
                            </button>
                        </div>
                    @endif

                    @if(session('error'))
                        <div x-data="{ show: true }" x-show="show" class="alert alert-error mb-6">
                            <i class="ti ti-alert-circle text-xl"></i>
                            <span class="font-semibold">{{ session('error') }}</span>
                            <button @click="show = false" class="btn btn-ghost btn-sm btn-circle absolute right-3 top-3">
                                <i class="ti ti-x text-sm"></i>
                            </button>
                        </div>
                    @endif

                    @yield('content')
                </main>
            </div>

            <div class="drawer-side sidebar-shell z-40">
                <label for="admin-drawer" class="drawer-overlay"></label>

                <aside class="sidebar-panel menu min-h-full w-[300px] p-5">
                    <div class="relative z-10 flex items-center gap-4 px-2 py-2">
                        <div class="brand-mark">
                            <i class="ti ti-heart-rate-monitor text-[1.65rem]"></i>
                        </div>
                        <div>
                            <h2 class="text-xl font-extrabold tracking-tight text-white">MediConnect</h2>
                            <p class="text-[10px] font-bold uppercase tracking-[0.28em] text-blue-200/70">Console medicale</p>
                        </div>
                    </div>

                    <div class="relative z-10 mt-5 rounded-[1.4rem] border border-white/10 bg-white/5 p-4 text-sm text-blue-50/85">
                        <div class="flex items-start gap-3">
                            <div class="mt-0.5 flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-400/15 text-emerald-300">
                                <i class="ti ti-shield-check"></i>
                            </div>
                            <div>
                                <p class="font-bold text-white">Back-office sous controle</p>
                                <p class="mt-1 text-xs leading-5 text-blue-100/70">
                                    Audit, administration et supervision centralises pour l'application medicale.
                                </p>
                            </div>
                        </div>
                    </div>

                    <ul class="relative z-10 mt-6 flex-1 space-y-1.5 overflow-y-auto pr-2 pb-6">
                        <li>
                            <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                                <i class="ti ti-layout-dashboard"></i>
                                Vue d'ensemble
                            </a>
                        </li>

                        <div class="section-label">Gestion</div>

                        <li>
                            <a href="{{ route('admin.users.index') }}" class="{{ request()->routeIs('admin.users.*') ? 'active' : '' }}">
                                <i class="ti ti-users-group"></i>
                                Utilisateurs / Patients
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.doctors.index', ['status' => 'pending']) }}" class="{{ request()->routeIs('admin.doctors.*') ? 'active' : '' }}">
                                <i class="ti ti-stethoscope"></i>
                                Approbations medecins
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.appointments.index') }}" class="{{ request()->routeIs('admin.appointments.*') ? 'active' : '' }}">
                                <i class="ti ti-calendar-event"></i>
                                Litiges & creneaux
                            </a>
                        </li>

                        <div class="section-label">Supervision</div>

                        <li>
                            <a href="{{ route('admin.chat.index') }}" class="{{ request()->routeIs('admin.chat.*') ? 'active' : '' }}">
                                <i class="ti ti-messages"></i>
                                Messages & signalements
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.medical-records.index') }}" class="{{ request()->routeIs('admin.medical-records.*') ? 'active' : '' }}">
                                <i class="ti ti-folder-open"></i>
                                Dossiers medicaux
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.rgpd.index') }}" class="{{ request()->routeIs('admin.rgpd.*') ? 'active' : '' }}">
                                <i class="ti ti-shield-lock"></i>
                                Droit a l'oubli / RGPD
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.notifications.index') }}" class="{{ request()->routeIs('admin.notifications.*') ? 'active' : '' }}">
                                <i class="ti ti-bell-ringing"></i>
                                Push notifications
                            </a>
                        </li>

                        <div class="section-label">Systeme</div>

                        <li>
                            <a href="{{ route('admin.reports.index') }}" class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}">
                                <i class="ti ti-chart-bar"></i>
                                Rapports analytiques
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.activity-log.index') }}" class="{{ request()->routeIs('admin.activity-log.*') ? 'active' : '' }}">
                                <i class="ti ti-history"></i>
                                Journal d'activite
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.settings.index') }}" class="{{ request()->routeIs('admin.settings.*') ? 'active' : '' }}">
                                <i class="ti ti-settings"></i>
                                Configuration API
                            </a>
                        </li>
                    </ul>

                    <div class="relative z-10 mt-auto rounded-[1.35rem] border border-white/10 bg-white/5 px-4 py-4 text-xs text-blue-100/70">
                        <div class="flex items-center justify-between gap-3">
                            <div>
                                <div class="font-bold uppercase tracking-[0.18em] text-blue-200/70">MediConnect Pro</div>
                                <div class="mt-1">SaaS medical multi-tenant</div>
                            </div>
                            <div class="rounded-full bg-emerald-400/15 px-3 py-1 font-bold text-emerald-300">
                                v1.0
                            </div>
                        </div>
                    </div>
                </aside>
            </div>
        </div>
    @else
        <main class="auth-canvas">
            <div class="auth-container">
                @yield('content')
            </div>
        </main>
    @endauth

    @livewireScripts
    @stack('scripts')
</body>
</html>
