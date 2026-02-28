<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AppointmentStatus;
use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\Request;

class AppointmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Appointment::with(['patient', 'doctor']);

        // Filter by status
        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        // Filter by date range
        if ($request->filled('from')) {
            $query->whereDate('starts_at_utc', '>=', $request->input('from'));
        }
        if ($request->filled('to')) {
            $query->whereDate('starts_at_utc', '<=', $request->input('to'));
        }

        // Search by patient or doctor name
        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->whereHas('patient', function ($pq) use ($search) {
                    $pq->where('first_name', 'LIKE', "%{$search}%")
                       ->orWhere('last_name', 'LIKE', "%{$search}%");
                })->orWhereHas('doctor', function ($dq) use ($search) {
                    $dq->where('first_name', 'LIKE', "%{$search}%")
                       ->orWhere('last_name', 'LIKE', "%{$search}%");
                });
            });
        }

        $appointments = $query->orderBy('starts_at_utc', 'desc')->paginate(15);

        $stats = [
            'today' => Appointment::whereDate('starts_at_utc', today())->count(),
            'pending' => Appointment::where('status', AppointmentStatus::REQUESTED)->count(),
            'confirmed' => Appointment::where('status', AppointmentStatus::CONFIRMED)->count(),
            'cancelled' => Appointment::where('status', AppointmentStatus::CANCELLED)->count(),
        ];

        return view('admin.appointments.index', compact('appointments', 'stats'));
    }

    public function show(string $appointmentId)
    {
        $appointment = Appointment::with(['patient', 'doctor', 'events'])
            ->findOrFail($appointmentId);

        return view('admin.appointments.show', compact('appointment'));
    }

    public function forceCancel(Request $request, string $appointmentId)
    {
        $request->validate([
            'cancel_reason' => ['required', 'string', 'max:500'],
        ]);

        $appointment = Appointment::findOrFail($appointmentId);

        if (in_array($appointment->status, [AppointmentStatus::CANCELLED, AppointmentStatus::COMPLETED])) {
            return back()->with('error', 'Ce rendez-vous ne peut pas être annulé.');
        }

        $appointment->update([
            'status' => AppointmentStatus::CANCELLED,
            'cancel_reason' => '[ADMIN] ' . $request->input('cancel_reason'),
        ]);

        return redirect()->route('admin.appointments.index')
            ->with('success', 'Rendez-vous annulé par l\'administrateur.');
    }
}
