<?php

namespace App\Http\Controllers\Api;

use App\Enums\SecretaryPermission;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\ScheduleSlotResource;
use App\Models\DoctorSchedule;
use App\Services\AuditService;
use App\Services\DelegationContextService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class ScheduleController extends Controller
{
    public function __construct(
        private readonly DelegationContextService $delegationContextService,
        private readonly AuditService $auditService,
    ) {}

    /**
     * List the authenticated doctor's schedule.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $doctorUserId = $this->resolveDoctorUserId($request);

        $schedules = DoctorSchedule::query()
            ->where('doctor_user_id', $doctorUserId)
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        $this->auditAction($request, 'schedule.viewed', [
            'doctor_user_id' => $doctorUserId,
            'count' => $schedules->count(),
        ]);

        return $this->respondSuccess(ScheduleSlotResource::collection($schedules), 'Schedule retrieved successfully');
    }

    /**
     * Create or update a schedule slot.
     */
    public function upsert(Request $request): JsonResponse
    {
        $doctorUserId = $this->resolveDoctorUserId($request);

        $data = $request->validate([
            'day_of_week' => 'required|integer|min:0|max:6',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'slot_duration_minutes' => 'nullable|integer|min:10|max:120',
            'is_active' => 'nullable|boolean',
        ]);

        $schedule = DoctorSchedule::query()->updateOrCreate(
            [
                'doctor_user_id' => $doctorUserId,
                'day_of_week' => $data['day_of_week'],
                'start_time' => $data['start_time'],
            ],
            [
                'end_time' => $data['end_time'],
                'slot_duration_minutes' => $data['slot_duration_minutes'] ?? 30,
                'is_active' => $data['is_active'] ?? true,
            ],
        );

        $this->auditAction($request, 'schedule.upserted', [
            'doctor_user_id' => $doctorUserId,
            'schedule_id' => $schedule->id,
        ]);

        return $this->respondSuccess([
            'schedule' => new ScheduleSlotResource($schedule),
        ], 'Schedule created successfully', 201);
    }

    /**
     * Delete a schedule slot.
     */
    public function destroy(string $scheduleId, Request $request): JsonResponse
    {
        $doctorUserId = $this->resolveDoctorUserId($request);

        $schedule = DoctorSchedule::query()
            ->where('id', $scheduleId)
            ->where('doctor_user_id', $doctorUserId)
            ->firstOrFail();

        $schedule->delete();

        $this->auditAction($request, 'schedule.deleted', [
            'doctor_user_id' => $doctorUserId,
            'schedule_id' => $scheduleId,
        ]);

        return $this->respondSuccess(null, 'Schedule slot deleted successfully');
    }

    /**
     * Bulk update schedule (replace all slots for the doctor).
     */
    public function bulkUpdate(Request $request): JsonResponse
    {
        $doctorUserId = $this->resolveDoctorUserId($request);

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
            ->where('doctor_user_id', $doctorUserId)
            ->delete();

        // Create new slots
        $createdSlots = collect($data['slots'])->map(function ($slot) use ($doctorUserId) {
            return DoctorSchedule::query()->create([
                'doctor_user_id' => $doctorUserId,
                'day_of_week' => $slot['day_of_week'],
                'start_time' => $slot['start_time'],
                'end_time' => $slot['end_time'],
                'slot_duration_minutes' => $slot['slot_duration_minutes'] ?? 30,
                'is_active' => $slot['is_active'] ?? true,
            ]);
        });

        $this->auditAction($request, 'schedule.bulk_updated', [
            'doctor_user_id' => $doctorUserId,
            'count' => $createdSlots->count(),
        ]);

        return $this->respondSuccess(ScheduleSlotResource::collection($createdSlots), 'Bulk schedule updated successfully');
    }

    private function resolveDoctorUserId(Request $request): string
    {
        $user = $request->user();

        if (in_array($user->role, [UserRole::DOCTOR, UserRole::ADMIN], true)) {
            return $user->id;
        }

        if ($user->role === UserRole::SECRETARY) {
            return $this->delegationContextService
                ->assertSecretaryPermission($request, SecretaryPermission::MANAGE_SCHEDULE)
                ->doctor_user_id;
        }

        throw new AccessDeniedHttpException('Only doctors or delegated secretaries can manage schedules');
    }

    private function auditAction(Request $request, string $event, array $context): void
    {
        $delegation = $request->attributes->get('doctor_delegation');

        $this->auditService->log(
            $request->user(),
            $event,
            DoctorSchedule::class,
            $context,
            $request->attributes->get('acting_doctor_user_id'),
            $delegation?->id,
            $request,
        );
    }
}
