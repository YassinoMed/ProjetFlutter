<!DOCTYPE html>
<html lang="fr" data-theme="corporate">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>MediConnect Pro - Administration</title>

    <!-- Tailwind CSS & DaisyUI (CDN) -->
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.10.1/dist/full.min.css" rel="stylesheet" type="text/css" />
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- AlpineJS v3 -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.8/dist/cdn.min.js"></script>
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <!-- Material Icons -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />

    <style>
        .material-symbols-rounded {
            font-variation-settings: 'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24;
            vertical-align: middle;
        }
        body { font-family: 'Inter', system-ui, sans-serif; }
    </style>
    
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        medical: {
                            50: '#f0fdfa',
                            100: '#ccfbf1',
                            500: '#14b8a6',
                            600: '#0d9488',
                            900: '#134e4a',
                        }
                    }
                }
            }
        }
    </script>

    @livewireStyles
</head>
<body class="bg-base-200 text-base-content min-h-screen flex">
    
    @auth('web')
        <!-- Navbar -->
        <div class="drawer lg:drawer-open flex-1">
            <input id="admin-drawer" type="checkbox" class="drawer-toggle" />
            
            <div class="drawer-content flex flex-col items-center justify-start min-h-screen">
                
                <!-- Navbar Superieure -->
                <div class="w-full navbar bg-base-100 shadow-sm z-50 px-4">
                    <div class="flex-none lg:hidden">
                        <label for="admin-drawer" class="btn btn-square btn-ghost">
                            <span class="material-symbols-rounded">menu</span>
                        </label>
                    </div>
                    
                    <div class="flex-1 lg:hidden">
                        <span class="text-xl font-bold text-primary">MediConnect Pro</span>
                    </div>
                    <div class="flex-1 hidden lg:block">
                        <!-- Breadcrumbs or page title could go here -->
                        <span class="text-sm text-gray-400">Pôle d'administration système</span>
                    </div>

                    <div class="flex-none gap-4">
                        <!-- Notifications -->
                        <div class="dropdown dropdown-end">
                            <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
                                <div class="indicator">
                                    <span class="material-symbols-rounded">notifications</span>
                                    <span class="badge badge-error badge-xs indicator-item"></span>
                                </div>
                            </div>
                        </div>

                        <!-- Theme Toggle (Alpine) -->
                        <label class="swap swap-rotate btn btn-ghost btn-circle">
                            <input type="checkbox" class="theme-controller" value="dark" />
                            <span class="material-symbols-rounded swap-off">light_mode</span>
                            <span class="material-symbols-rounded swap-on">dark_mode</span>
                        </label>

                        <!-- Profile -->
                        <div class="dropdown dropdown-end">
                            <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                                <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                                    <span class="font-bold">{{ substr(auth()->user()->first_name ?? 'A', 0, 1) }}</span>
                                </div>
                            </div>
                            <ul tabindex="0" class="mt-3 z-[1] p-2 shadow menu menu-sm dropdown-content bg-base-100 rounded-box w-52 border border-base-200">
                                <li>
                                    <a href="{{ route('admin.profile.index') }}" class="py-3">
                                        <span class="material-symbols-rounded text-lg">admin_panel_settings</span>
                                        Mon Profil Admin
                                    </a>
                                </li>
                                <div class="divider my-0"></div>
                                <li>
                                    <form method="POST" action="{{ route('admin.logout') }}" class="w-full m-0 p-0">
                                        @csrf
                                        <button type="submit" class="w-full text-left text-error hover:bg-error/10 py-3 flex items-center gap-2">
                                            <span class="material-symbols-rounded text-lg">logout</span>
                                            Déconnexion
                                        </button>
                                    </form>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>

                <!-- Page Content -->
                <main class="p-6 w-full max-w-[1400px] mx-auto bg-base-200">
                    <!-- Flash Messages -->
                    @if(session('success'))
                        <div x-data="{ show: true }" x-show="show" class="alert alert-success shadow-sm mb-6 rounded-lg">
                            <span class="material-symbols-rounded">check_circle</span>
                            <span>{{ session('success') }}</span>
                            <button @click="show = false" class="btn btn-ghost btn-sm btn-circle absolute right-2"><span class="material-symbols-rounded text-sm">close</span></button>
                        </div>
                    @endif
                    
                    @if(session('error'))
                        <div x-data="{ show: true }" x-show="show" class="alert alert-error shadow-sm mb-6 rounded-lg">
                            <span class="material-symbols-rounded">error</span>
                            <span>{{ session('error') }}</span>
                            <button @click="show = false" class="btn btn-ghost btn-sm btn-circle absolute right-2"><span class="material-symbols-rounded text-sm">close</span></button>
                        </div>
                    @endif

                    @yield('content')
                </main>
            </div> 

            <!-- Sidebar Drawer -->
            <div class="drawer-side z-40 shadow-xl border-r border-base-200">
                <label for="admin-drawer" class="drawer-overlay"></label> 
                <div class="menu p-4 w-72 h-full bg-base-100 text-base-content flex flex-col">
                    
                    <!-- Logo Area -->
                    <div class="flex items-center gap-3 px-2 mb-8 mt-2">
                        <div class="bg-primary text-primary-content p-2 rounded-xl flex items-center justify-center">
                            <span class="material-symbols-rounded text-2xl">health_and_safety</span>
                        </div>
                        <div>
                            <h2 class="text-xl font-extrabold text-primary">MediConnect</h2>
                            <p class="text-xs uppercase font-semibold text-gray-400 tracking-wider">Administration</p>
                        </div>
                    </div>

                    <ul class="flex-1 space-y-1">
                        <!-- 1. Dashboard -->
                        <li>
                            <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">view_dashboard</span>
                                Vue d'ensemble
                            </a>
                        </li>

                        <div class="divider mt-6 mb-2 text-xs font-bold uppercase text-gray-400">Gestion</div>
                        
                        <!-- 2. Utilisateurs -->
                        <li>
                            <a href="{{ route('admin.users.index') }}" class="{{ request()->routeIs('admin.users.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">manage_accounts</span>
                                Utilisateurs / Patients
                            </a>
                        </li>
                        <li>
                            <a href="{{ route('admin.doctors.index', ['status' => 'pending']) }}" class="{{ request()->routeIs('admin.doctors.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">stethoscope</span>
                                Approbations Médecins
                            </a>
                        </li>

                        <!-- 3. Rendez-vous -->
                        <li>
                            <a href="{{ route('admin.appointments.index') }}" class="{{ request()->routeIs('admin.appointments.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">event</span>
                                Litiges & Créneaux
                            </a>
                        </li>

                        <div class="divider mt-6 mb-2 text-xs font-bold uppercase text-gray-400">Supervision</div>

                        <!-- 4. Chat & Messages -->
                        <li>
                            <a href="{{ route('admin.chat.index') }}" class="{{ request()->routeIs('admin.chat.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">forum</span>
                                Messages & Signalements
                            </a>
                        </li>

                        <!-- 5. Dossiers Médicaux -->
                        <li>
                            <a href="{{ route('admin.medical-records.index') }}" class="{{ request()->routeIs('admin.medical-records.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">folder_shared</span>
                                Dossiers Médicaux
                            </a>
                        </li>

                        <!-- 6. RGPD -->
                        <li>
                            <a href="{{ route('admin.rgpd.index') }}" class="{{ request()->routeIs('admin.rgpd.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">shield_person</span>
                                Droit à l'oubli / RGPD
                            </a>
                        </li>
                        
                        <!-- 7. Notifications -->
                        <li>
                            <a href="{{ route('admin.notifications.index') }}" class="{{ request()->routeIs('admin.notifications.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">campaign</span>
                                Push Notifications
                            </a>
                        </li>

                        <div class="divider mt-6 mb-2 text-xs font-bold uppercase text-gray-400">Système</div>

                        <!-- 8. Rapports -->
                        <li>
                            <a href="{{ route('admin.reports.index') }}" class="{{ request()->routeIs('admin.reports.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">monitoring</span>
                                Rapports analytiques
                            </a>
                        </li>

                        <!-- 9. Audit Log -->
                        <li>
                            <a href="{{ route('admin.activity-log.index') }}" class="{{ request()->routeIs('admin.activity-log.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">receipt_long</span>
                                Journal d'Activité
                            </a>
                        </li>

                        <!-- 10. Paramètres -->
                        <li>
                            <a href="{{ route('admin.settings.index') }}" class="{{ request()->routeIs('admin.settings.*') ? 'active bg-primary/10 text-primary font-bold' : 'hover:bg-base-200' }}">
                                <span class="material-symbols-rounded">settings</span>
                                Configuration API
                            </a>
                        </li>
                    </ul>
                    
                    <div class="mt-auto px-2 py-4 text-xs text-center text-gray-400">
                        MediConnect Pro v1.0<br>
                        Système SaaS Multi-Tenant
                    </div>
                </div>
            </div>
        </div>
    @else
        <!-- Guest Login View -->
        <main class="w-full flex items-center justify-center p-4">
            @yield('content')
        </main>
    @endauth

    @livewireScripts
    @stack('scripts')
</body>
</html>
