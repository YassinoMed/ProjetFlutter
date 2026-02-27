<div wire:poll.30s>
    <!-- Top Stats Row -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Card 1 -->
        <div class="stats bg-blue-50 text-blue-800 shadow-sm border border-blue-100">
            <div class="stat">
                <div class="stat-figure text-blue-400">
                    <span class="material-symbols-rounded text-4xl">groups</span>
                </div>
                <div class="stat-title text-blue-600 font-medium">Patients Inscrits</div>
                <div class="stat-value">{{ $patientsCount }}</div>
                <div class="stat-desc text-blue-500">↗︎ +2.4% vs dernière semaine</div>
            </div>
        </div>

        <!-- Card 2 -->
        <div class="stats bg-emerald-50 text-emerald-800 shadow-sm border border-emerald-100">
            <div class="stat">
                <div class="stat-figure text-emerald-400">
                    <span class="material-symbols-rounded text-4xl">stethoscope</span>
                </div>
                <div class="stat-title text-emerald-600 font-medium">Médecins Vérifiés</div>
                <div class="stat-value">{{ $doctorsCount }}</div>
                <div class="stat-desc text-emerald-500">2 dossiers en attente</div>
            </div>
        </div>

        <!-- Card 3 -->
        <div class="stats bg-purple-50 text-purple-800 shadow-sm border border-purple-100">
            <div class="stat">
                <div class="stat-figure text-purple-400">
                    <span class="material-symbols-rounded text-4xl">event_available</span>
                </div>
                <div class="stat-title text-purple-600 font-medium">RDV Aujourd'hui</div>
                <div class="stat-value">{{ $appointmentsToday }}</div>
                <div class="stat-desc text-purple-500">4 visio / {{ $appointmentsToday - 4 }} cabinet</div>
            </div>
        </div>

        <!-- Card 4 -->
        <div class="stats bg-amber-50 text-amber-800 shadow-sm border border-amber-100">
            <div class="stat">
                <div class="stat-figure text-amber-400">
                    <span class="material-symbols-rounded text-4xl">payments</span>
                </div>
                <div class="stat-title text-amber-600 font-medium">CA Géré (Est.)</div>
                <div class="stat-value">{{ $revenueToday }} MAD</div>
                <div class="stat-desc text-amber-500">Basé sur consultations terminées</div>
            </div>
        </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Chart 1: Evolution des RDV -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body">
                <h2 class="card-title text-lg font-bold">Évolution des Rendez-vous (7 jours)</h2>
                <div class="h-72 w-full mt-4">
                    <canvas id="appointmentsChart"></canvas>
                </div>
            </div>
        </div>

        <!-- System Alerts / Logs -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body">
                <h2 class="card-title text-lg font-bold text-error">
                    Alertes & Litiges Récents
                </h2>
                <ul class="list-none mt-4 space-y-3">
                    <li class="p-3 bg-red-50 text-red-800 rounded-lg flex gap-3 border border-red-100">
                        <span class="material-symbols-rounded text-red-500">warning</span>
                        <div class="flex-1">
                            <p class="font-bold text-sm">NO-SHOW répété : Patient #1224</p>
                            <p class="text-xs">3 rendez-vous non honorés ce mois-ci.</p>
                        </div>
                        <button class="btn btn-xs btn-outline btn-error">Gérer</button>
                    </li>
                    <li class="p-3 bg-orange-50 text-orange-800 rounded-lg flex gap-3 border border-orange-100">
                        <span class="material-symbols-rounded text-orange-500">person_off</span>
                        <div class="flex-1">
                            <p class="font-bold text-sm">Médecin "Dr H." bloqué suite à signalements</p>
                            <p class="text-xs">Suspension automatique par sécurité.</p>
                        </div>
                        <button class="btn btn-xs btn-outline btn-warning">Contrôler</button>
                    </li>
                    <li class="p-3 bg-blue-50 text-blue-800 rounded-lg flex gap-3 border border-blue-100">
                        <span class="material-symbols-rounded text-blue-500">gavel</span>
                        <div class="flex-1">
                            <p class="font-bold text-sm">Demande Article 17 (Droit à l'oubli)</p>
                            <p class="text-xs">Patient requiert la suppression totale via app PWA.</p>
                        </div>
                        <button class="btn btn-xs btn-outline btn-info">Exécuter</button>
                    </li>
                </ul>
                <div class="card-actions justify-end mt-4">
                    <button class="btn btn-sm btn-ghost text-primary leading-none">Voir tout</button>
                </div>
            </div>
        </div>
    </div>

</div>

<!-- Dispatch Chart initialization after Livewire loads -->
@script
<script>
    document.addEventListener('livewire:initialized', () => {
        const ctx = document.getElementById('appointmentsChart').getContext('2d');
        const labels = @json($chartLabels);
        const dataVals = @json($chartData);

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'RDV créés',
                    data: dataVals,
                    borderColor: '#3b82f6', // blue-500
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: { stepSize: 1 }
                    }
                }
            }
        });
    });
</script>
@endscript
