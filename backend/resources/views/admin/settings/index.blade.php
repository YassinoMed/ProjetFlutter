@extends('admin.layouts.app')

@section('content')
<div class="mb-6">
    <h1 class="text-3xl font-bold text-base-content">Configuration Système</h1>
    <p class="text-sm text-base-content/70 mt-1">Paramètres de la plateforme et maintenance</p>
</div>

<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Application Info -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-primary">info</span>
                Informations Application
            </h2>
            <div class="overflow-x-auto">
                <table class="table table-sm">
                    <tbody>
                        <tr>
                            <td class="font-bold text-gray-400">Nom</td>
                            <td>{{ e($settings['app_name']) }}</td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Environnement</td>
                            <td>
                                <span class="badge {{ $settings['app_env'] === 'production' ? 'badge-success' : 'badge-warning' }} badge-sm">
                                    {{ e($settings['app_env']) }}
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Mode Debug</td>
                            <td>
                                @if($settings['app_debug'])
                                    <span class="badge badge-error badge-sm gap-1">
                                        <span class="material-symbols-rounded text-xs">warning</span>
                                        Activé
                                    </span>
                                @else
                                    <span class="badge badge-success badge-sm gap-1">
                                        <span class="material-symbols-rounded text-xs">check</span>
                                        Désactivé
                                    </span>
                                @endif
                            </td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">PHP</td>
                            <td class="font-mono text-sm">{{ e($settings['php_version']) }}</td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Laravel</td>
                            <td class="font-mono text-sm">{{ e($settings['laravel_version']) }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Drivers Configuration -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-secondary">settings</span>
                Configuration Drivers
            </h2>
            <div class="overflow-x-auto">
                <table class="table table-sm">
                    <tbody>
                        <tr>
                            <td class="font-bold text-gray-400">Mail</td>
                            <td><span class="badge badge-ghost badge-sm">{{ e($settings['mail_driver']) }}</span></td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Cache</td>
                            <td><span class="badge badge-ghost badge-sm">{{ e($settings['cache_driver']) }}</span></td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Queue</td>
                            <td><span class="badge badge-ghost badge-sm">{{ e($settings['queue_driver']) }}</span></td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Session</td>
                            <td><span class="badge badge-ghost badge-sm">{{ e($settings['session_driver']) }}</span></td>
                        </tr>
                        <tr>
                            <td class="font-bold text-gray-400">Session TTL</td>
                            <td>{{ e($settings['session_lifetime']) }} min</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Security Status -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-success">security</span>
                Sécurité
            </h2>
            <div class="space-y-3">
                <div class="flex items-center justify-between p-3 bg-base-200/50 rounded-lg">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-rounded text-sm text-success">check_circle</span>
                        <span class="text-sm font-medium">CSRF Protection</span>
                    </div>
                    <span class="badge badge-success badge-xs">Actif</span>
                </div>
                <div class="flex items-center justify-between p-3 bg-base-200/50 rounded-lg">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-rounded text-sm text-success">check_circle</span>
                        <span class="text-sm font-medium">Security Headers (HSTS, X-Frame, etc.)</span>
                    </div>
                    <span class="badge badge-success badge-xs">Actif</span>
                </div>
                <div class="flex items-center justify-between p-3 bg-base-200/50 rounded-lg">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-rounded text-sm text-success">check_circle</span>
                        <span class="text-sm font-medium">Rate Limiting (API)</span>
                    </div>
                    <span class="badge badge-success badge-xs">Actif</span>
                </div>
                <div class="flex items-center justify-between p-3 bg-base-200/50 rounded-lg">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-rounded text-sm text-success">check_circle</span>
                        <span class="text-sm font-medium">JWT Authentication (API)</span>
                    </div>
                    <span class="badge badge-success badge-xs">Actif</span>
                </div>
                <div class="flex items-center justify-between p-3 bg-base-200/50 rounded-lg">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-rounded text-sm text-success">check_circle</span>
                        <span class="text-sm font-medium">E2EE Chat Encryption</span>
                    </div>
                    <span class="badge badge-success badge-xs">Actif</span>
                </div>
                <div class="flex items-center justify-between p-3 bg-base-200/50 rounded-lg">
                    <div class="flex items-center gap-2">
                        <span class="material-symbols-rounded text-sm text-success">check_circle</span>
                        <span class="text-sm font-medium">Distributed Tracing (OpenTelemetry)</span>
                    </div>
                    <span class="badge badge-success badge-xs">Actif</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Maintenance Actions -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-warning">build</span>
                Maintenance
            </h2>
            <div class="space-y-4">
                <div class="p-4 border border-base-200 rounded-lg">
                    <h3 class="font-bold text-sm mb-2">Vider le Cache</h3>
                    <p class="text-xs text-gray-400 mb-3">Supprime le cache de configuration, de vues et de routes.</p>
                    <form method="POST" action="{{ route('admin.settings.clear-cache') }}" class="inline">
                        @csrf
                        <button type="submit" class="btn btn-warning btn-sm">
                            <span class="material-symbols-rounded text-sm">delete_sweep</span>
                            Vider tous les caches
                        </button>
                    </form>
                </div>

                <div class="p-4 border border-base-200 rounded-lg">
                    <h3 class="font-bold text-sm mb-2">Informations Serveur</h3>
                    <div class="text-xs text-gray-400 space-y-1">
                        <p><strong>Mémoire PHP :</strong> {{ ini_get('memory_limit') }}</p>
                        <p><strong>Upload max :</strong> {{ ini_get('upload_max_filesize') }}</p>
                        <p><strong>Temps d'exécution max :</strong> {{ ini_get('max_execution_time') }}s</p>
                        <p><strong>Extensions :</strong> {{ implode(', ', array_slice(get_loaded_extensions(), 0, 10)) }}...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
