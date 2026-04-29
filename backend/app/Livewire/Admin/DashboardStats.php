<?php

namespace App\Livewire\Admin;

use App\Enums\UserRole;
use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class DashboardStats extends Component
{
    // Statistiques clés (Temps réel)
    public $totalPatients = 0;

    public $totalDoctors = 0;

    public $appointmentsToday = 0;

    public $activeConversations = 0;

    // Pourcentage changement réel
    public $patientsGrowth = '0%';

    public $doctorsGrowth = '0%';

    // Chart datas
    public $appointmentsChartLabels = [];

    public $appointmentsChartData = [];

    public $specialtiesChartLabels = [];

    public $specialtiesChartData = [];

    // Recent activity
    public $recentUsers = [];

    public $recentAppointments = [];

    public function mount()
    {
        $this->loadStats();
    }

    public function loadStats()
    {
        $today = Carbon::today();

        // 1. Statistiques principales
        $this->totalPatients = Patient::count();
        $this->totalDoctors = Doctor::count();
        $this->appointmentsToday = Appointment::whereDate('starts_at_utc', $today)->count();

        // Active conversations: consultations with messages in last 24h
        $this->activeConversations = ChatMessage::where('sent_at_utc', '>=', now()->subDay())
            ->distinct('consultation_id')
            ->count('consultation_id');

        // 2. Growth percentages (refactored: extracted to helper method)
        $this->patientsGrowth = $this->calculateGrowth(UserRole::PATIENT);
        $this->doctorsGrowth = $this->calculateGrowth(UserRole::DOCTOR);

        // 3. Weekly Appointments Chart
        // Refactored: single query instead of N+1 loop (was 7 separate queries)
        $weeklyData = Appointment::where('starts_at_utc', '>=', (clone $today)->subDays(6))
            ->where('starts_at_utc', '<', (clone $today)->addDay())
            ->selectRaw('DATE(starts_at_utc) as date, COUNT(*) as count')
            ->groupBy('date')
            ->orderBy('date')
            ->pluck('count', 'date');

        $this->appointmentsChartLabels = [];
        $this->appointmentsChartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $d = (clone $today)->subDays($i);
            $this->appointmentsChartLabels[] = $d->format('D d');
            $this->appointmentsChartData[] = $weeklyData[$d->format('Y-m-d')] ?? 0;
        }

        // 4. Specialties Distribution
        $specialties = Doctor::select('specialty', DB::raw('count(*) as count'))
            ->whereNotNull('specialty')
            ->groupBy('specialty')
            ->orderByDesc('count')
            ->limit(6)
            ->get();

        $this->specialtiesChartLabels = $specialties->pluck('specialty')->toArray();
        $this->specialtiesChartData = $specialties->pluck('count')->toArray();

        if (empty($this->specialtiesChartLabels)) {
            $this->specialtiesChartLabels = ['Aucune spécialité'];
            $this->specialtiesChartData = [0];
        }

        // 5. Recent activity
        $this->recentUsers = User::latest()
            ->take(5)
            ->get(['id', 'first_name', 'last_name', 'email', 'role', 'created_at'])
            ->toArray();

        $this->recentAppointments = Appointment::with(['patient:id,first_name,last_name', 'doctor:id,first_name,last_name'])
            ->latest('starts_at_utc')
            ->take(5)
            ->get()
            ->toArray();
    }

    /**
     * Calculate month-over-month growth for a given role.
     *
     * Refactored: extracted duplicated growth logic for patients and doctors
     * into a single reusable method.
     */
    private function calculateGrowth(UserRole $role): string
    {
        $thisMonth = User::where('role', $role)
            ->where('created_at', '>=', now()->startOfMonth())
            ->count();

        $lastMonth = User::where('role', $role)
            ->whereBetween('created_at', [
                now()->subMonth()->startOfMonth(),
                now()->subMonth()->endOfMonth(),
            ])
            ->count();

        if ($lastMonth > 0) {
            $pct = round(($thisMonth - $lastMonth) / $lastMonth * 100);

            return ($pct >= 0 ? '+' : '').$pct.'%';
        }

        return '+'.$thisMonth;
    }

    public function render()
    {
        return view('livewire.admin.dashboard-stats');
    }
}
