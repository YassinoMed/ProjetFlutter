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
    public $patientsGrowth = "0%";
    public $doctorsGrowth = "0%";

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
        // 1. Statistiques principales
        $this->totalPatients = Patient::count();
        $this->totalDoctors = Doctor::count();

        $today = Carbon::today();

        $this->appointmentsToday = Appointment::whereDate('starts_at_utc', $today)->count();

        // Active conversations: consultations with messages in last 24h
        $this->activeConversations = ChatMessage::where('sent_at_utc', '>=', now()->subDay())
            ->distinct('consultation_id')
            ->count('consultation_id');

        // 2. Growth percentages (real calculation)
        $patientsThisMonth = User::where('role', UserRole::PATIENT)
            ->where('created_at', '>=', now()->startOfMonth())->count();
        $patientsLastMonth = User::where('role', UserRole::PATIENT)
            ->whereBetween('created_at', [now()->subMonth()->startOfMonth(), now()->subMonth()->endOfMonth()])
            ->count();
        $this->patientsGrowth = $patientsLastMonth > 0
            ? '+' . round(($patientsThisMonth - $patientsLastMonth) / $patientsLastMonth * 100) . '%'
            : '+' . $patientsThisMonth;

        $doctorsThisMonth = User::where('role', UserRole::DOCTOR)
            ->where('created_at', '>=', now()->startOfMonth())->count();
        $doctorsLastMonth = User::where('role', UserRole::DOCTOR)
            ->whereBetween('created_at', [now()->subMonth()->startOfMonth(), now()->subMonth()->endOfMonth()])
            ->count();
        $this->doctorsGrowth = $doctorsLastMonth > 0
            ? '+' . round(($doctorsThisMonth - $doctorsLastMonth) / $doctorsLastMonth * 100) . '%'
            : '+' . $doctorsThisMonth;

        // 3. Weekly Appointments Chart
        $this->appointmentsChartLabels = [];
        $this->appointmentsChartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $d = (clone $today)->subDays($i);
            $this->appointmentsChartLabels[] = $d->format('D d');
            $this->appointmentsChartData[] = Appointment::whereDate('starts_at_utc', $d)->count();
        }

        // 4. Specialties Distribution (real data)
        $specialties = Doctor::select('specialty', DB::raw('count(*) as count'))
            ->whereNotNull('specialty')
            ->groupBy('specialty')
            ->orderByDesc('count')
            ->limit(6)
            ->get();

        $this->specialtiesChartLabels = $specialties->pluck('specialty')->toArray();
        $this->specialtiesChartData = $specialties->pluck('count')->toArray();

        // Fallback if no specialties exist
        if (empty($this->specialtiesChartLabels)) {
            $this->specialtiesChartLabels = ['Aucune spécialité'];
            $this->specialtiesChartData = [0];
        }

        // 5. Recent users (for dashboard activity feed)
        $this->recentUsers = User::latest()
            ->take(5)
            ->get(['id', 'first_name', 'last_name', 'email', 'role', 'created_at'])
            ->toArray();

        // 6. Recent appointments
        $this->recentAppointments = Appointment::with(['patient:id,first_name,last_name', 'doctor:id,first_name,last_name'])
            ->latest('starts_at_utc')
            ->take(5)
            ->get()
            ->toArray();
    }

    public function render()
    {
        return view('livewire.admin.dashboard-stats');
    }
}
