<?php

namespace App\Http\Controllers\Api;

use App\Enums\AppointmentStatus;
use App\Enums\SecretaryPermission;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Appointments\CancelAppointmentRequest;
use App\Http\Requests\Appointments\CreateAppointmentRequest;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Services\Appointments\AppointmentBookingService;
use App\Services\Appointments\AppointmentStateService;
use App\Services\AuditService;
use App\Services\DelegationContextService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class AppointmentController extends Controller
{
    public function __construct(
        private readonly AppointmentBookingService $booking,
        private readonly AppointmentStateService $states,
        private readonly DelegationContextService $delegationContextService,
        private readonly AuditService $auditService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Appointment::query()
            ->with(['patient:id,first_name,last_name', 'doctor:id,first_name,last_name'])
            ->when($request->filled('doctor_user_id'), fn ($q) => $q->where('doctor_user_id', $request->string('doctor_user_id')))
            ->when($request->filled('patient_user_id'), fn ($q) => $q->where('patient_user_id', $request->string('patient_user_id')))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when($request->filled('from_utc'), fn ($q) => $q->where('starts_at_utc', '>=', Carbon::parse($request->string('from_utc'), 'UTC')))
            ->when($request->filled('to_utc'), fn ($q) => $q->where('starts_at_utc', '<=', Carbon::parse($request->string('to_utc'), 'UTC')))
            ->when($request->filled('updated_since_utc'), fn ($q) => $q->where('updated_at', '>', Carbon::parse($request->string('updated_since_utc'), 'UTC')));

        if ($user->role === UserRole::SECRETARY) {
            $doctorUserId = $this->delegationContextService
                ->assertSecretaryPermission($request, SecretaryPermission::MANAGE_APPOINTMENTS)
                ->doctor_user_id;

            $query->where('doctor_user_id', $doctorUserId);
        } elseif ($user->role !== UserRole::ADMIN) {
            $query->where(function ($q) use ($user) {
                $q->where('patient_user_id', $user->id)->orWhere('doctor_user_id', $user->id);
            });
        }

        $appointments = $query
            ->orderBy('starts_at_utc')
            ->cursorPaginate(min(max((int) $request->query('per_page', 20), 1), 50));

        $delegation = $request->attributes->get('doctor_delegation');
        $this->auditService->log(
            $request->user(),
            'appointments.viewed',
            Appointment::class,
            ['count' => count($appointments->items())],
            $request->attributes->get('acting_doctor_user_id'),
            $delegation?->id,
            $request,
        );

        return $this->respondSuccess(
            AppointmentResource::collection(collect($appointments->items())),
            'Appointments retrieved successfully',
            200,
            ['next_cursor' => $appointments->nextCursor()?->encode()]
        );
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

        return $this->respondSuccess([
            'appointment' => new AppointmentResource($appointment),
        ], 'Appointment created successfully', 201);
    }

    public function show(string $appointmentId, Request $request): JsonResponse
    {
        $appointment = Appointment::query()
            ->with(['patient:id,first_name,last_name', 'doctor:id,first_name,last_name'])
            ->findOrFail($appointmentId);

        $this->authorizeAppointmentAccess($request, $appointment);

        return $this->respondSuccess([
            'appointment' => new AppointmentResource($appointment),
        ], 'Appointment details retrieved');
    }

    public function cancel(string $appointmentId, CancelAppointmentRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorizeCancel($request, $appointment);

        $appointment = $this->states->transition(
            appointment: $appointment,
            to: AppointmentStatus::CANCELLED,
            actorUserId: $request->user()->id,
            metadataEncrypted: $request->validated()['metadata_encrypted'] ?? null,
            cancelReason: $request->validated()['cancel_reason'] ?? null,
        );

        $delegation = $request->attributes->get('doctor_delegation');
        $this->auditService->log(
            $request->user(),
            'appointment.cancelled',
            $appointment,
            ['appointment_id' => $appointment->id],
            $request->attributes->get('acting_doctor_user_id'),
            $delegation?->id,
            $request,
        );

        return $this->respondSuccess([
            'appointment' => new AppointmentResource($appointment),
        ], 'Appointment cancelled successfully');
    }

    public function reject(string $appointmentId, CancelAppointmentRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorizeAppointmentAccess($request, $appointment, SecretaryPermission::MANAGE_APPOINTMENTS, true);

        if ($appointment->status !== AppointmentStatus::REQUESTED) {
            throw new ConflictHttpException('Only pending appointments can be rejected.');
        }

        $appointment = $this->states->transition(
            appointment: $appointment,
            to: AppointmentStatus::CANCELLED,
            actorUserId: $request->user()->id,
            metadataEncrypted: $request->validated()['metadata_encrypted'] ?? null,
            cancelReason: $request->validated()['cancel_reason'] ?? 'Rejected by medical office',
            eventName: 'rejected',
        );

        $delegation = $request->attributes->get('doctor_delegation');
        $this->auditService->log(
            $request->user(),
            'appointment.rejected',
            $appointment,
            ['appointment_id' => $appointment->id],
            $request->attributes->get('acting_doctor_user_id'),
            $delegation?->id,
            $request,
        );

        return $this->respondSuccess([
            'appointment' => new AppointmentResource($appointment),
        ], 'Appointment rejected successfully');
    }

    public function confirm(string $appointmentId, Request $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorizeAppointmentAccess($request, $appointment, SecretaryPermission::MANAGE_APPOINTMENTS, true);

        $appointment = $this->states->transition(
            appointment: $appointment,
            to: AppointmentStatus::CONFIRMED,
            actorUserId: $request->user()->id,
        );

        $delegation = $request->attributes->get('doctor_delegation');
        $this->auditService->log(
            $request->user(),
            'appointment.confirmed',
            $appointment,
            ['appointment_id' => $appointment->id],
            $request->attributes->get('acting_doctor_user_id'),
            $delegation?->id,
            $request,
        );

        return $this->respondSuccess([
            'appointment' => new AppointmentResource($appointment),
        ], 'Appointment confirmed successfully');
    }

    private function authorizeCancel(Request $request, Appointment $appointment): void
    {
        $user = $request->user();

        if ($user->role === UserRole::PATIENT && $appointment->patient_user_id === $user->id) {
            if ($appointment->status !== AppointmentStatus::REQUESTED) {
                throw new ConflictHttpException('Patients can cancel only before medical office confirmation.');
            }

            return;
        }

        $this->authorizeAppointmentAccess($request, $appointment, SecretaryPermission::MANAGE_APPOINTMENTS);
    }

    private function authorizeAppointmentAccess(
        Request $request,
        Appointment $appointment,
        SecretaryPermission $secretaryPermission = SecretaryPermission::MANAGE_APPOINTMENTS,
        bool $useConfirmAbility = false,
    ): void {
        $user = $request->user();

        if ($user->role === UserRole::SECRETARY) {
            if (! $this->delegationContextService->canAccessAppointment($request, $appointment, $secretaryPermission)) {
                throw new AccessDeniedHttpException('You are not allowed to access this appointment.');
            }

            return;
        }

        $ability = $secretaryPermission === SecretaryPermission::MANAGE_APPOINTMENTS ? 'update' : 'view';

        if ($ability === 'view') {
            $this->authorize('view', $appointment);

            return;
        }

        if ($useConfirmAbility) {
            $this->authorize('confirm', $appointment);

            return;
        }

        $this->authorize('update', $appointment);
    }
}
