<?php

namespace App\Livewire\Admin;

use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Message; // Assumes Message model exists
use App\Models\Patient;
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
    
    // Pourcentage changement (fake stats over yesterday for UI)
    public $patientsGrowth = "+12%";
    public $doctorsGrowth = "+2%";
    
    // Chart datas
    public $appointmentsChartLabels = [];
    public $appointmentsChartData = [];
    public $specialtiesChartLabels = [];
    public $specialtiesChartData = [];

    // Rafraichissement par websockets (ou polling fallback)
    // On pourrait utiliser Wire:poll dans la vue
    
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
        
        $this->appointmentsToday = Appointment::whereDate('starts_at_utc', clone $today)->count();
        $this->activeConversations = 25; // TODO: Count rows in chats/messages recent logic
        
        // 2. Data for Weekly Appointments (Chart.js)
        $this->appointmentsChartLabels = [];
        $this->appointmentsChartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $d = clone $today;
            $d->subDays($i);
            $this->appointmentsChartLabels[] = $d->format('D d');
            $this->appointmentsChartData[] = Appointment::whereDate('starts_at_utc', $d)->count() ?? rand(5,20); // Fallback random just to verify chart loads
        }
        
        // 3. Data for Specialties Distribution (Chart.js)
        // Grouper les médecins par spécialité (simulation si table specialization_id non countée ici)
        $this->specialtiesChartLabels = ['Cardiologie', 'Dermatologie', 'Pédiatrie', 'Généraliste', 'Ophtalmologie'];
        $this->specialtiesChartData = [
            Doctor::where('specialty_id', 1)->count() ?: 12,
            Doctor::where('specialty_id', 2)->count() ?: 8,
            Doctor::where('specialty_id', 3)->count() ?: 15,
            Doctor::where('specialty_id', 4)->count() ?: 30,
            Doctor::where('specialty_id', 5)->count() ?: 5,
        ];
    }

    public function render()
    {
        return view('livewire.admin.dashboard-stats');
    }
}
