<div wire:poll.30s="loadStats">
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="metric-card p-5 text-indigo-600">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Patients</div>
                    <div class="mt-2 text-3xl font-black text-slate-900">{{ $totalPatients }}</div>
                    <div class="mt-3 inline-flex items-center gap-1 rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-600">
                        <i class="ti ti-trending-up text-sm"></i>
                        {{ $patientsGrowth }} ce mois
                    </div>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.2rem] bg-indigo-50">
                    <i class="ti ti-users text-[1.65rem]"></i>
                </div>
            </div>
        </div>

        <div class="metric-card p-5 text-emerald-600">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Medecins inscrits</div>
                    <div class="mt-2 text-3xl font-black text-slate-900">{{ $totalDoctors }}</div>
                    <div class="mt-3 inline-flex items-center gap-1 rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-600">
                        <i class="ti ti-trending-up text-sm"></i>
                        {{ $doctorsGrowth }} ce mois
                    </div>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.2rem] bg-emerald-50">
                    <i class="ti ti-stethoscope text-[1.65rem]"></i>
                </div>
            </div>
        </div>

        <div class="metric-card p-5 text-sky-600">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Rendez-vous aujourd'hui</div>
                    <div class="mt-2 text-3xl font-black text-slate-900">{{ $appointmentsToday }}</div>
                    <div class="mt-3 inline-flex items-center gap-1 rounded-full bg-amber-50 px-3 py-1 text-xs font-bold text-amber-600">
                        <i class="ti ti-clock-hour-4 text-sm"></i>
                        Supervision temps reel
                    </div>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.2rem] bg-sky-50">
                    <i class="ti ti-calendar text-[1.65rem]"></i>
                </div>
            </div>
        </div>

        <div class="metric-card p-5 text-fuchsia-600">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <div class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Discussions actives</div>
                    <div class="mt-2 text-3xl font-black text-slate-900">{{ $activeConversations }}</div>
                    <div class="mt-3 inline-flex items-center gap-1 rounded-full bg-fuchsia-50 px-3 py-1 text-xs font-bold text-fuchsia-600">
                        <i class="ti ti-messages text-sm"></i>
                        Flux WebSocket chiffre
                    </div>
                </div>
                <div class="flex h-14 w-14 items-center justify-center rounded-[1.2rem] bg-fuchsia-50">
                    <i class="ti ti-message-circle text-[1.65rem]"></i>
                </div>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="card lg:col-span-2">
            <div class="card-body p-6 sm:p-7">
                <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                        <p class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Activite</p>
                        <h2 class="card-title mt-2 text-lg font-extrabold text-slate-900">Rendez-vous, 7 derniers jours</h2>
                    </div>
                    <select class="select select-sm border-slate-200 bg-slate-50 text-slate-600 focus:ring-0">
                        <option>Cette semaine</option>
                        <option>Ce mois</option>
                    </select>
                </div>
                <div class="h-[300px] w-full relative">
                    <canvas id="appointmentsChart"></canvas>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-body p-6 sm:p-7">
                <p class="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">Mix medecins</p>
                <h2 class="card-title mt-2 mb-6 text-lg font-extrabold text-slate-900">Repartition specialites</h2>
                <div class="h-[250px] w-full relative flex items-center justify-center">
                    <canvas id="specialtiesChart"></canvas>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('livewire:initialized', () => {
            window.mediconnectAdminCharts ??= {};

            const appointmentsCanvas = document.getElementById('appointmentsChart');
            const specialtiesCanvas = document.getElementById('specialtiesChart');

            if (!appointmentsCanvas || !specialtiesCanvas) {
                return;
            }

            const ctxAppts = appointmentsCanvas.getContext('2d');
            const ctxSpecs = specialtiesCanvas.getContext('2d');

            window.mediconnectAdminCharts.appointments?.destroy();
            window.mediconnectAdminCharts.specialties?.destroy();

            window.mediconnectAdminCharts.appointments = new Chart(ctxAppts, {
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
                        y: {
                            beginAtZero: true,
                            ticks: { color: '#64748b' },
                            grid: { color: 'rgba(148, 163, 184, 0.18)', borderDash: [5, 5] }
                        },
                        x: {
                            ticks: { color: '#64748b' },
                            grid: { display: false }
                        }
                    }
                }
            });

            window.mediconnectAdminCharts.specialties = new Chart(ctxSpecs, {
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
                        legend: {
                            position: 'bottom',
                            labels: {
                                usePointStyle: true,
                                padding: 20,
                                color: '#475569'
                            }
                        }
                    }
                }
            });
        });
    </script>
</div>
