<?php

namespace App\Http\Controllers\Api;

use App\Enums\AppointmentStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Appointments\CancelAppointmentRequest;
use App\Http\Requests\Appointments\CreateAppointmentRequest;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Services\Appointments\AppointmentBookingService;
use App\Services\Appointments\AppointmentStateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class AppointmentController extends Controller
{
    public function __construct(
        private readonly AppointmentBookingService $booking,
        private readonly AppointmentStateService $states,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Appointment::query()
            ->when($request->filled('doctor_user_id'), fn ($q) => $q->where('doctor_user_id', $request->string('doctor_user_id')))
            ->when($request->filled('patient_user_id'), fn ($q) => $q->where('patient_user_id', $request->string('patient_user_id')))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when($request->filled('from_utc'), fn ($q) => $q->where('starts_at_utc', '>=', Carbon::parse($request->string('from_utc'), 'UTC')))
            ->when($request->filled('to_utc'), fn ($q) => $q->where('starts_at_utc', '<=', Carbon::parse($request->string('to_utc'), 'UTC')));

        if ($user->role !== UserRole::ADMIN) {
            $query->where(function ($q) use ($user) {
                $q->where('patient_user_id', $user->id)->orWhere('doctor_user_id', $user->id);
            });
        }

        $appointments = $query
            ->orderBy('starts_at_utc')
            ->cursorPaginate(min(max((int) $request->query('per_page', 20), 1), 50));

        return response()->json([
            'data' => AppointmentResource::collection(collect($appointments->items())),
            'next_cursor' => $appointments->nextCursor()?->encode(),
        ]);
    }

    public function store(CreateAppointmentRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! in_array($user->role, [UserRole::PATIENT, UserRole::ADMIN], true)) {
            throw new AccessDeniedHttpException;
        }

        $data = $request->validated();

        $appointment = $this->booking->createRequested(
            patientUserId: $user->id,
            doctorUserId: $data['doctor_user_id'],
            startsAtUtc: Carbon::parse($data['starts_at_utc'], 'UTC'),
            endsAtUtc: Carbon::parse($data['ends_at_utc'], 'UTC'),
            metadataEncrypted: $data['metadata_encrypted'] ?? null,
        );

        return response()->json([
            'appointment' => new AppointmentResource($appointment),
        ], 201);
    }

    public function show(string $appointmentId, Request $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        return response()->json([
            'appointment' => new AppointmentResource($appointment),
        ]);
    }

    public function cancel(string $appointmentId, CancelAppointmentRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('update', $appointment);

        $appointment = $this->states->transition(
            appointment: $appointment,
            to: AppointmentStatus::CANCELLED,
            actorUserId: $request->user()->id,
            metadataEncrypted: $request->validated()['metadata_encrypted'] ?? null,
            cancelReason: $request->validated()['cancel_reason'] ?? null,
        );

        return response()->json([
            'appointment' => new AppointmentResource($appointment),
        ]);
    }

    public function confirm(string $appointmentId, Request $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('confirm', $appointment);

        $appointment = $this->states->transition(
            appointment: $appointment,
            to: AppointmentStatus::CONFIRMED,
            actorUserId: $request->user()->id,
        );

        return response()->json([
            'appointment' => new AppointmentResource($appointment),
        ]);
    }
}
