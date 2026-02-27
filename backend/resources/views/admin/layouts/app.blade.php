<!DOCTYPE html>
<html lang="fr" data-theme="light">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>MediConnect Pro - Administration</title>

    <!-- Tailwind CSS (via CDN for simplicity, or compile with Vite if configured) -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.10.1/dist/full.min.css" rel="stylesheet" type="text/css" />
    
    <!-- AlpineJS for UI toggles -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.8/dist/cdn.min.js"></script>
    
    <!-- Icons Material -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />

    <style>
        .material-symbols-rounded {
            font-variation-settings: 'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        body { font-family: 'Inter', sans-serif; }
    </style>

    @livewireStyles
</head>
<body class="bg-base-200 min-h-screen">
    
    @auth('web')
        <!-- Navbar -->
        <div class="navbar bg-base-100 shadow-sm sticky top-0 z-50 px-4">
            <div class="flex-none lg:hidden">
                <label for="my-drawer-2" class="btn btn-square btn-ghost">
                    <span class="material-symbols-rounded">menu</span>
                </label>
            </div>
            
            <div class="flex-1">
                <a class="btn btn-ghost text-xl text-primary font-bold">
                    <span class="material-symbols-rounded text-primary">medical_services</span>
                    MediConnect Admin
                </a>
            </div>

            <div class="flex-none gap-2">
                <!-- Notifications -->
                <div class="dropdown dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
                        <div class="indicator">
                            <span class="material-symbols-rounded">notifications</span>
                            <span class="badge badge-error badge-sm indicator-item text-white">3</span>
                        </div>
                    </div>
                </div>

                <!-- Theme Toggle -->
                <label class="swap swap-rotate btn btn-ghost btn-circle">
                    <input type="checkbox" class="theme-controller" value="dark" />
                    <span class="material-symbols-rounded swap-off">light_mode</span>
                    <span class="material-symbols-rounded swap-on">dark_mode</span>
                </label>

                <!-- Profile Dropdown -->
                <div class="dropdown dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                        <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                            <span class="text-xl font-bold">{{ substr(auth()->user()->first_name ?? 'A', 0, 1) }}</span>
                        </div>
                    </div>
                    <ul tabindex="0" class="mt-3 z-[1] p-2 shadow menu menu-sm dropdown-content bg-base-100 rounded-box w-52">
                        <li>
                            <a class="justify-between">
                                Profile
                                <span class="badge">New</span>
                            </a>
                        </li>
                        <li><a>Settings</a></li>
                        <li>
                            <form method="POST" action="{{ route('admin.logout') }}" class="w-full">
                                @csrf
                                <button type="submit" class="w-full text-left text-error">Logout</button>
                            </form>
                        </li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="drawer lg:drawer-open flex-1">
            <input id="my-drawer-2" type="checkbox" class="drawer-toggle" />
            
            <!-- PAGE CONTENT -->
            <div class="drawer-content p-6 max-w-7xl mx-auto w-full">
                @if(session('success'))
                    <div class="alert alert-success shadow-lg mb-6">
                        <span class="material-symbols-rounded">check_circle</span>
                        <span>{{ session('success') }}</span>
                    </div>
                @endif
                
                @if($errors->any())
                    <div class="alert alert-error shadow-lg mb-6">
                        <span class="material-symbols-rounded">error</span>
                        <ul>
                            @foreach($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                @yield('content')
            </div> 

            <!-- SIDEBAR -->
            <div class="drawer-side z-40">
                <label for="my-drawer-2" class="drawer-overlay"></label> 
                <ul class="menu p-4 w-72 h-full bg-base-100 text-base-content border-r border-base-200">
                    <li class="menu-title mt-4">Menu Principal</li>
                    
                    <li>
                        <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                            <span class="material-symbols-rounded">dashboard</span>
                            Tableau de bord
                        </a>
                    </li>
                    
                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">group</span>
                            Utilisateurs
                        </a>
                    </li>
                    
                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">medical_information</span>
                            Médecins & Approbations
                            <span class="badge badge-sm badge-warning">2</span>
                        </a>
                    </li>
                    
                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">calendar_month</span>
                            Rendez-vous
                        </a>
                    </li>

                    <li class="menu-title mt-6">Supervision & Outils</li>

                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">forum</span>
                            Logs Conversations
                        </a>
                    </li>
                    
                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">folder_supervised</span>
                            Droit à l'oubli (RGPD)
                        </a>
                    </li>

                    <li class="menu-title mt-6">Système</li>
                    
                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">monitoring</span>
                            Rapports & Logs
                        </a>
                    </li>
                    
                    <li>
                        <a href="#">
                            <span class="material-symbols-rounded">settings</span>
                            Paramètres API
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    @else
        <!-- Guest view (Login) -->
        <div class="flex items-center justify-center min-h-screen p-4">
            @yield('content')
        </div>
    @endauth

    <!-- ChartJS for dashboard -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    @livewireScripts
    @stack('scripts')
</body>
</html>
