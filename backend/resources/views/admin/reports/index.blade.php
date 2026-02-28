@extends('admin.layouts.app')

@section('content')
<div class="mb-6 flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
    <div>
        <h1 class="text-3xl font-bold text-base-content">Rapports & Statistiques</h1>
        <p class="text-sm text-base-content/70 mt-1">Analytiques de la plateforme MediConnect Pro</p>
    </div>

    <form method="GET" action="{{ route('admin.reports.index') }}" class="flex gap-2">
        <select name="period" class="select select-bordered select-sm" onchange="this.form.submit()">
            <option value="7" {{ $period == '7' ? 'selected' : '' }}>7 jours</option>
            <option value="30" {{ $period == '30' ? 'selected' : '' }}>30 jours</option>
            <option value="90" {{ $period == '90' ? 'selected' : '' }}>90 jours</option>
            <option value="365" {{ $period == '365' ? 'selected' : '' }}>1 an</option>
        </select>
    </form>
</div>

<!-- KPI Cards -->
<div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Utilisateurs Totaux</div>
                    <div class="text-2xl font-bold text-primary mt-1">{{ number_format($stats['total_users']) }}</div>
                </div>
                <div class="bg-primary/10 p-3 rounded-xl text-primary">
                    <span class="material-symbols-rounded text-2xl">groups</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Patients</div>
                    <div class="text-2xl font-bold text-info mt-1">{{ number_format($stats['total_patients']) }}</div>
                </div>
                <div class="bg-info/10 p-3 rounded-xl text-info">
                    <span class="material-symbols-rounded text-2xl">person</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">Médecins</div>
                    <div class="text-2xl font-bold text-success mt-1">{{ number_format($stats['total_doctors']) }}</div>
                </div>
                <div class="bg-success/10 p-3 rounded-xl text-success">
                    <span class="material-symbols-rounded text-2xl">stethoscope</span>
                </div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-4">
            <div class="flex items-center justify-between">
                <div>
                    <div class="text-xs text-gray-400 font-bold uppercase">RDV (période)</div>
                    <div class="text-2xl font-bold text-accent mt-1">{{ number_format($stats['appointments_this_period']) }}</div>
                </div>
                <div class="bg-accent/10 p-3 rounded-xl text-accent">
                    <span class="material-symbols-rounded text-2xl">event</span>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Rate Cards -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-5 flex-row items-center gap-4">
            <div class="radial-progress text-success" style="--value:{{ intval($stats['completion_rate']) }}; --size:4rem; --thickness:4px;" role="progressbar">
                <span class="text-sm font-bold">{{ $stats['completion_rate'] }}</span>
            </div>
            <div>
                <div class="text-xs text-gray-400 font-bold uppercase">Taux de complétion</div>
                <div class="text-sm text-gray-500">RDV terminés avec succès</div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-5 flex-row items-center gap-4">
            <div class="radial-progress text-error" style="--value:{{ intval($stats['cancellation_rate']) }}; --size:4rem; --thickness:4px;" role="progressbar">
                <span class="text-sm font-bold">{{ $stats['cancellation_rate'] }}</span>
            </div>
            <div>
                <div class="text-xs text-gray-400 font-bold uppercase">Taux d'annulation</div>
                <div class="text-sm text-gray-500">RDV annulés sur la période</div>
            </div>
        </div>
    </div>
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body p-5 flex-row items-center gap-4">
            <div class="bg-info/10 p-3 rounded-xl text-info">
                <span class="material-symbols-rounded text-2xl">chat</span>
            </div>
            <div>
                <div class="text-xs text-gray-400 font-bold uppercase">Messages (période)</div>
                <div class="text-2xl font-bold text-info">{{ number_format($stats['messages_this_period']) }}</div>
            </div>
        </div>
    </div>
</div>

<!-- Charts Section -->
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- User Growth Chart -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-primary">trending_up</span>
                Croissance des Utilisateurs
            </h2>
            <div class="h-[300px] w-full relative">
                <canvas id="userGrowthChart"></canvas>
            </div>
        </div>
    </div>

    <!-- Daily Appointments Chart -->
    <div class="card bg-base-100 shadow-sm border border-base-200">
        <div class="card-body">
            <h2 class="card-title text-lg font-bold mb-4">
                <span class="material-symbols-rounded text-accent">event</span>
                Rendez-vous Quotidiens
            </h2>
            <div class="h-[300px] w-full relative">
                <canvas id="dailyAppointmentsChart"></canvas>
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', () => {
        // User Growth Chart
        const userGrowthCtx = document.getElementById('userGrowthChart').getContext('2d');
        new Chart(userGrowthCtx, {
            type: 'bar',
            data: {
                labels: @json($userGrowth->pluck('date')->map(fn($d) => \Carbon\Carbon::parse($d)->format('d/m'))),
                datasets: [{
                    label: 'Nouveaux utilisateurs',
                    data: @json($userGrowth->pluck('count')),
                    backgroundColor: '#14b8a6',
                    borderRadius: 6,
                    barThickness: 12,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, grid: { borderDash: [5, 5] } },
                    x: { grid: { display: false } }
                }
            }
        });

        // Daily Appointments Chart
        const dailyCtx = document.getElementById('dailyAppointmentsChart').getContext('2d');
        new Chart(dailyCtx, {
            type: 'line',
            data: {
                labels: @json($dailyAppointments->pluck('date')->map(fn($d) => \Carbon\Carbon::parse($d)->format('d/m'))),
                datasets: [{
                    label: 'Rendez-vous',
                    data: @json($dailyAppointments->pluck('count')),
                    borderColor: '#8b5cf6',
                    backgroundColor: 'rgba(139, 92, 246, 0.1)',
                    tension: 0.4,
                    fill: true,
                    pointBackgroundColor: '#8b5cf6',
                    borderWidth: 2,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, grid: { borderDash: [5, 5] } },
                    x: { grid: { display: false } }
                }
            }
        });
    });
</script>
@endpush
@endsection
