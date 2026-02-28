<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AppointmentStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $period = $request->input('period', '30'); // days
        $from = Carbon::today()->subDays((int) $period);

        // User growth
        $userGrowth = User::where('created_at', '>=', $from)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Appointment statistics
        $appointmentStats = Appointment::where('starts_at_utc', '>=', $from)
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status')
            ->toArray();

        // Daily appointments
        $dailyAppointments = Appointment::where('starts_at_utc', '>=', $from)
            ->selectRaw('DATE(starts_at_utc) as date, COUNT(*) as count')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Summary stats
        $stats = [
            'total_users' => User::count(),
            'total_patients' => Patient::count(),
            'total_doctors' => Doctor::count(),
            'total_appointments' => Appointment::count(),
            'appointments_this_period' => Appointment::where('starts_at_utc', '>=', $from)->count(),
            'completion_rate' => $this->calculateRate(
                Appointment::where('status', AppointmentStatus::COMPLETED)->where('starts_at_utc', '>=', $from)->count(),
                Appointment::where('starts_at_utc', '>=', $from)->count()
            ),
            'cancellation_rate' => $this->calculateRate(
                Appointment::where('status', AppointmentStatus::CANCELLED)->where('starts_at_utc', '>=', $from)->count(),
                Appointment::where('starts_at_utc', '>=', $from)->count()
            ),
            'messages_this_period' => ChatMessage::where('sent_at_utc', '>=', $from)->count(),
        ];

        return view('admin.reports.index', compact(
            'stats', 'userGrowth', 'appointmentStats', 'dailyAppointments', 'period'
        ));
    }

    private function calculateRate(int $part, int $total): string
    {
        if ($total === 0) return '0%';
        return round(($part / $total) * 100, 1) . '%';
    }
}
