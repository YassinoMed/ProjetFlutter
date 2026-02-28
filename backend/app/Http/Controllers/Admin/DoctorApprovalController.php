<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Doctor;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DoctorApprovalController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->input('status', 'pending');

        $query = Doctor::with('user');

        // Filter by approval status
        switch ($status) {
            case 'pending':
                $query->where('is_approved', false)->where('is_rejected', false);
                break;
            case 'approved':
                $query->where('is_approved', true);
                break;
            case 'rejected':
                $query->where('is_rejected', true);
                break;
        }

        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('first_name', 'LIKE', "%{$search}%")
                  ->orWhere('last_name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            })->orWhere('rpps', 'LIKE', "%{$search}%");
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

        Log::channel('security')->info('doctor_approved', [
            'admin_id' => auth('web')->id(),
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

        Log::channel('security')->info('doctor_rejected', [
            'admin_id' => auth('web')->id(),
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
