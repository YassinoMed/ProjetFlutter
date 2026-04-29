<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\LogsAdminActivity;
use App\Http\Controllers\Admin\Concerns\SearchesUsers;
use App\Http\Controllers\Controller;
use App\Models\Doctor;
use Illuminate\Http\Request;

class DoctorApprovalController extends Controller
{
    use LogsAdminActivity;
    use SearchesUsers;

    public function index(Request $request)
    {
        $status = $request->input('status', 'pending');

        $query = Doctor::with('user');

        // Filter by approval status
        match ($status) {
            'pending' => $query->where('is_approved', false)->where('is_rejected', false),
            'approved' => $query->where('is_approved', true),
            'rejected' => $query->where('is_rejected', true),
            default => null,
        };

        // Refactored: use shared trait + RPPS-specific search
        if ($request->filled('search')) {
            $search = $request->input('search');
            $this->applyRelatedUserSearch($query, 'user', $search);
            $query->orWhere('rpps', 'LIKE', "%{$search}%");
        }

        $doctors = $query->orderByDesc('created_at')->paginate(15);

        $stats = [
            'pending' => Doctor::where('is_approved', false)->where('is_rejected', false)->count(),
            'approved' => Doctor::where('is_approved', true)->count(),
            'rejected' => Doctor::where('is_rejected', true)->count(),
            'total' => Doctor::count(),
        ];

        return view('admin.doctors.index', compact('doctors', 'stats', 'status'));
    }

    public function approve(Request $request, string $doctorUserId)
    {
        $doctor = Doctor::where('user_id', $doctorUserId)->firstOrFail();

        $doctor->update([
            'is_approved' => true,
            'is_rejected' => false,
            'approved_at' => now(),
            'approved_by' => auth('web')->id(),
        ]);

        // Refactored: uses LogsAdminActivity trait
        $this->logAdminAction('doctor_approved', [
            'doctor_user_id' => $doctorUserId,
            'rpps' => $doctor->rpps,
        ]);

        return redirect()->route('admin.doctors.index')
            ->with('success', "Le Dr. {$doctor->user->first_name} {$doctor->user->last_name} a été approuvé.");
    }

    public function reject(Request $request, string $doctorUserId)
    {
        $request->validate([
            'rejection_reason' => ['required', 'string', 'max:500'],
        ]);

        $doctor = Doctor::where('user_id', $doctorUserId)->firstOrFail();

        $doctor->update([
            'is_approved' => false,
            'is_rejected' => true,
            'rejection_reason' => $request->input('rejection_reason'),
            'rejected_by' => auth('web')->id(),
        ]);

        // Refactored: uses LogsAdminActivity trait
        $this->logAdminAction('doctor_rejected', [
            'doctor_user_id' => $doctorUserId,
            'reason' => $request->input('rejection_reason'),
        ]);

        return redirect()->route('admin.doctors.index')
            ->with('success', "Le Dr. {$doctor->user->first_name} {$doctor->user->last_name} a été refusé.");
    }

    public function show(string $doctorUserId)
    {
        $doctor = Doctor::with(['user', 'schedules'])->where('user_id', $doctorUserId)->firstOrFail();

        return view('admin.doctors.show', compact('doctor'));
    }
}
