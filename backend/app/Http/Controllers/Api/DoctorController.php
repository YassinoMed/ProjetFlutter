<?php

namespace App\Http\Controllers\Api;

use App\Enums\AppointmentStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\DoctorSearchResource;
use App\Http\Resources\ScheduleSlotResource;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\DoctorSchedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DoctorController extends Controller
{
    /**
     * Search and list doctors with optional filters.
     *
     * GET /api/doctors?specialty=&city=&q=&video_only=&per_page=20
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'specialty' => 'nullable|string|max:128',
            'city' => 'nullable|string|max:128',
            'q' => 'nullable|string|max:128',
            'video_only' => 'nullable|boolean',
            'per_page' => 'nullable|integer|min:1|max:50',
        ]);

        $perPage = min(max((int) $request->query('per_page', 20), 1), 50);

        $query = Doctor::query()
            ->with('user:id,first_name,last_name,email,phone')
            ->join('users', 'doctors.user_id', '=', 'users.id')
            ->where('users.role', UserRole::DOCTOR->value)
            ->select('doctors.*');

        // Filter by specialty
        if ($request->filled('specialty')) {
            $query->where('doctors.specialty', 'LIKE', '%' . $request->string('specialty') . '%');
        }

        // Filter by city
        if ($request->filled('city')) {
            $query->where('doctors.city', 'LIKE', '%' . $request->string('city') . '%');
        }

        // Full-text search on name, specialty, city
        if ($request->filled('q')) {
            $search = $request->string('q');
            $query->where(function ($q) use ($search) {
                $q->where('users.first_name', 'LIKE', "%{$search}%")
                    ->orWhere('users.last_name', 'LIKE', "%{$search}%")
                    ->orWhere('doctors.specialty', 'LIKE', "%{$search}%")
                    ->orWhere('doctors.city', 'LIKE', "%{$search}%");
            });
        }

        // Filter video-capable doctors only
        if ($request->boolean('video_only')) {
            $query->where('doctors.is_available_for_video', true);
        }

        $doctors = $query
            ->orderByDesc('doctors.rating')
            ->cursorPaginate($perPage);

        return $this->respondSuccess(
            DoctorSearchResource::collection(collect($doctors->items())),
            'Doctors retrieved successfully',
            200,
            ['next_cursor' => $doctors->nextCursor()?->encode()]
        );
    }

    /**
     * Get a single doctor's profile.
     *
     * GET /api/doctors/{doctorUserId}
     */
    public function show(string $doctorUserId): JsonResponse
    {
        $doctor = Doctor::query()
            ->with(['user:id,first_name,last_name,email,phone', 'schedules' => fn ($q) => $q->where('is_active', true)->orderBy('day_of_week')->orderBy('start_time')])
            ->where('user_id', $doctorUserId)
            ->firstOrFail();

        return $this->respondSuccess([
            'doctor' => new DoctorSearchResource($doctor),
        ]);
    }

    /**
     * Get available time slots for a doctor on a specific date.
     *
     * GET /api/doctors/{doctorUserId}/slots?date=2026-03-01
     */
    public function slots(string $doctorUserId, Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'required|date|after_or_equal:today',
        ]);

        $date = Carbon::parse($request->string('date'));
        $dayOfWeek = (int) $date->dayOfWeek; // 0 = Sunday

        // Get doctor's schedule for this day of week
        $schedules = DoctorSchedule::query()
            ->where('doctor_user_id', $doctorUserId)
            ->where('day_of_week', $dayOfWeek)
            ->where('is_active', true)
            ->get();

        if ($schedules->isEmpty()) {
            return $this->respondSuccess(['slots' => []]);
        }

        // Get existing appointments for this date
        $existingAppointments = Appointment::query()
            ->where('doctor_user_id', $doctorUserId)
            ->whereIn('status', [AppointmentStatus::REQUESTED, AppointmentStatus::CONFIRMED])
            ->whereDate('starts_at_utc', $date->toDateString())
            ->get(['starts_at_utc', 'ends_at_utc']);

        $slots = [];

        foreach ($schedules as $schedule) {
            $slotStart = $date->copy()->setTimeFromTimeString($schedule->start_time);
            $slotEnd = $date->copy()->setTimeFromTimeString($schedule->end_time);
            $duration = $schedule->slot_duration_minutes;

            while ($slotStart->copy()->addMinutes($duration)->lte($slotEnd)) {
                $slotEndTime = $slotStart->copy()->addMinutes($duration);

                // Check if slot is in the past
                if ($slotStart->lt(now('UTC'))) {
                    $slotStart = $slotEndTime;
                    continue;
                }

                // Check for conflicts
                $isBooked = $existingAppointments->contains(function ($appt) use ($slotStart, $slotEndTime) {
                    return $appt->starts_at_utc->lt($slotEndTime) && $appt->ends_at_utc->gt($slotStart);
                });

                $slots[] = [
                    'starts_at_utc' => $slotStart->setTimezone('UTC')->toISOString(),
                    'ends_at_utc' => $slotEndTime->setTimezone('UTC')->toISOString(),
                    'duration_minutes' => $duration,
                    'is_available' => ! $isBooked,
                ];

                $slotStart = $slotEndTime;
            }
        }

        return $this->respondSuccess([
            'date' => $date->toDateString(),
            'doctor_user_id' => $doctorUserId,
            'slots' => $slots,
        ]);
    }

    /**
     * Get doctor specialties list.
     *
     * GET /api/doctors/specialties
     */
    public function specialties(): JsonResponse
    {
        $specialties = Doctor::query()
            ->whereNotNull('specialty')
            ->distinct()
            ->pluck('specialty')
            ->sort()
            ->values();

        return $this->respondSuccess([
            'specialties' => $specialties,
        ]);
    }
}
