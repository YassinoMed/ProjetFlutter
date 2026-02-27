<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\ScheduleSlotResource;
use App\Models\DoctorSchedule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class ScheduleController extends Controller
{
    /**
     * List the authenticated doctor's schedule.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->assertIsDoctor($user);

        $schedules = DoctorSchedule::query()
            ->where('doctor_user_id', $user->id)
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        return response()->json([
            'data' => ScheduleSlotResource::collection($schedules),
        ]);
    }

    /**
     * Create or update a schedule slot.
     */
    public function upsert(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->assertIsDoctor($user);

        $data = $request->validate([
            'day_of_week' => 'required|integer|min:0|max:6',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'slot_duration_minutes' => 'nullable|integer|min:10|max:120',
            'is_active' => 'nullable|boolean',
        ]);

        $schedule = DoctorSchedule::query()->updateOrCreate(
            [
                'doctor_user_id' => $user->id,
                'day_of_week' => $data['day_of_week'],
                'start_time' => $data['start_time'],
            ],
            [
                'end_time' => $data['end_time'],
                'slot_duration_minutes' => $data['slot_duration_minutes'] ?? 30,
                'is_active' => $data['is_active'] ?? true,
            ],
        );

        return response()->json([
            'schedule' => new ScheduleSlotResource($schedule),
        ], 201);
    }

    /**
     * Delete a schedule slot.
     */
    public function destroy(string $scheduleId, Request $request): JsonResponse
    {
        $user = $request->user();
        $this->assertIsDoctor($user);

        $schedule = DoctorSchedule::query()
            ->where('id', $scheduleId)
            ->where('doctor_user_id', $user->id)
            ->firstOrFail();

        $schedule->delete();

        return response()->json(['ok' => true]);
    }

    /**
     * Bulk update schedule (replace all slots for the doctor).
     */
    public function bulkUpdate(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->assertIsDoctor($user);

        $data = $request->validate([
            'slots' => 'required|array|min:1|max:21',
            'slots.*.day_of_week' => 'required|integer|min:0|max:6',
            'slots.*.start_time' => 'required|date_format:H:i',
            'slots.*.end_time' => 'required|date_format:H:i|after:slots.*.start_time',
            'slots.*.slot_duration_minutes' => 'nullable|integer|min:10|max:120',
            'slots.*.is_active' => 'nullable|boolean',
        ]);

        // Delete all existing slots
        DoctorSchedule::query()
            ->where('doctor_user_id', $user->id)
            ->delete();

        // Create new slots
        $createdSlots = collect($data['slots'])->map(function ($slot) use ($user) {
            return DoctorSchedule::query()->create([
                'doctor_user_id' => $user->id,
                'day_of_week' => $slot['day_of_week'],
                'start_time' => $slot['start_time'],
                'end_time' => $slot['end_time'],
                'slot_duration_minutes' => $slot['slot_duration_minutes'] ?? 30,
                'is_active' => $slot['is_active'] ?? true,
            ]);
        });

        return response()->json([
            'data' => ScheduleSlotResource::collection($createdSlots),
        ]);
    }

    private function assertIsDoctor($user): void
    {
        if (! in_array($user->role, [UserRole::DOCTOR, UserRole::ADMIN], true)) {
            throw new AccessDeniedHttpException('Only doctors can manage schedules');
        }
    }
}
