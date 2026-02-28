<div wire:poll.30s="loadStats">
    <!-- Top Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        
        <!-- Total Patients -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body p-5">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-sm text-gray-400 font-semibold uppercase tracking-wider">Patients (Total)</div>
                        <div class="text-3xl font-bold mt-1 text-primary">{{ $totalPatients }}</div>
                        <div class="text-xs text-success font-semibold flex items-center mt-2">
                            <span class="material-symbols-rounded text-sm">trending_up</span> 
                            <span>{{ $patientsGrowth }} ce mois</span>
                        </div>
                    </div>
                    <div class="bg-primary/10 p-4 rounded-xl text-primary">
                        <span class="material-symbols-rounded text-3xl">groups</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Total Doctors -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body p-5">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-sm text-gray-400 font-semibold uppercase tracking-wider">Médecins Inscrits</div>
                        <div class="text-3xl font-bold mt-1 text-secondary">{{ $totalDoctors }}</div>
                        <div class="text-xs text-success font-semibold flex items-center mt-2">
                            <span class="material-symbols-rounded text-sm">trending_up</span> 
                            <span>{{ $doctorsGrowth }} ce mois</span>
                        </div>
                    </div>
                    <div class="bg-secondary/10 p-4 rounded-xl text-secondary">
                        <span class="material-symbols-rounded text-3xl">stethoscope</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Appointments Today -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body p-5">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-sm text-gray-400 font-semibold uppercase tracking-wider">Rendez-vous Aujourd'hui</div>
                        <div class="text-3xl font-bold mt-1 text-accent">{{ $appointmentsToday }}</div>
                        <div class="text-xs text-warning font-semibold flex items-center mt-2">
                            <span class="material-symbols-rounded text-sm">schedule</span> 
                            <span>Supervision temps réel</span>
                        </div>
                    </div>
                    <div class="bg-accent/10 p-4 rounded-xl text-accent">
                        <span class="material-symbols-rounded text-3xl">today</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Active Chats -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body p-5">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-sm text-gray-400 font-semibold uppercase tracking-wider">Discussions Actives</div>
                        <div class="text-3xl font-bold mt-1 text-info">{{ $activeConversations }}</div>
                        <div class="text-xs text-info font-semibold flex items-center mt-2">
                            <span class="material-symbols-rounded text-sm">chat</span> 
                            <span>Flux WebSocket chiffré</span>
                        </div>
                    </div>
                    <div class="bg-info/10 p-4 rounded-xl text-info">
                        <span class="material-symbols-rounded text-3xl">forum</span>
                    </div>
                </div>
            </div>
        </div>
        
    </div>

    <!-- Charts Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Large Chart (Appointments) -->
        <div class="card bg-base-100 shadow-sm border border-base-200 lg:col-span-2">
            <div class="card-body">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="card-title text-lg font-bold">Rendez-vous (7 derniers jours)</h2>
                    <select class="select select-sm select-bordered">
                        <option>Cette semaine</option>
                        <option>Ce mois</option>
                    </select>
                </div>
                <div class="h-[300px] w-full relative">
                    <canvas id="appointmentsChart"></canvas>
                </div>
            </div>
        </div>

        <!-- Small Chart (Specialties) -->
        <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body">
                <h2 class="card-title text-lg font-bold mb-4">Répartition Spécialités</h2>
                <div class="h-[250px] w-full relative flex items-center justify-center">
                    <canvas id="specialtiesChart"></canvas>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Alpine + Chart.js logic tied to Livewire data -->
    <script>
        document.addEventListener('livewire:initialized', () => {
            // Contexts
            const ctxAppts = document.getElementById('appointmentsChart').getContext('2d');
            const ctxSpecs = document.getElementById('specialtiesChart').getContext('2d');
            
            // Render Appts Line Chart
            new Chart(ctxAppts, {
                type: 'line',
                data: {
                    labels: @json($appointmentsChartLabels),
                    datasets: [{
                        label: 'Nouveaux RDV',
                        data: @json($appointmentsChartData),
                        borderColor: '#14b8a6', // tailwind teal-500
                        backgroundColor: '#ccfbf1', // teal-100
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: '#14b8a6',
                        borderWidth: 2
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

            // Render Specialties Doughnut Chart
            new Chart(ctxSpecs, {
                type: 'doughnut',
                data: {
                    labels: @json($specialtiesChartLabels),
                    datasets: [{
                        data: @json($specialtiesChartData),
                        backgroundColor: [
                            '#14b8a6', // Primary / Medical
                            '#0ea5e9', // Info
                            '#8b5cf6', // Indigo
                            '#f43f5e', // Rose
                            '#f59e0b', // Amber
                        ],
                        borderWidth: 0,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: '70%',
                    plugins: {
                        legend: { position: 'bottom', labels: { usePointStyle: true, padding: 20 } }
                    }
                }
            });
        });
    </script>
</div>
