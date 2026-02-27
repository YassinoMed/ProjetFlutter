<?php

namespace App\Livewire\Admin;

use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Carbon\Carbon;
use Livewire\Component;

class DashboardStats extends Component
{
    public $patientsCount = 0;
    public $doctorsCount = 0;
    public $appointmentsToday = 0;
    public $revenueToday = 0;

    // For charts
    public $chartLabels = [];
    public $chartData = [];

    // Optional: Refresh periodically for real-time without websockets
    protected $listeners = ['echo:admin,StatsUpdated' => 'refreshStats'];

    public function mount()
    {
        $this->refreshStats();
    }

    public function refreshStats()
    {
        $this->patientsCount = Patient::count();
        $this->doctorsCount = Doctor::count();
        
        $today = Carbon::today();
        
        // Appointments today
        $appointments = Appointment::whereDate('starts_at_utc', clone $today)->get();
        $this->appointmentsToday = $appointments->count();
        
        // Very basic mock of revenue or completed appointments count
        $this->revenueToday = $appointments->where('status', 'COMPLETED')->count() * 100; // Mock calculation 

        // Prepare simple 7-day chart data
        $this->chartLabels = [];
        $this->chartData = [];
        
        for ($i = 6; $i >= 0; $i--) {
            $date = clone $today;
            $date->subDays($i);
            $this->chartLabels[] = $date->format('d/m');
            $this->chartData[] = Appointment::whereDate('starts_at_utc', $date)->count();
        }
    }

    public function render()
    {
        return view('livewire.admin.dashboard-stats');
    }
}
