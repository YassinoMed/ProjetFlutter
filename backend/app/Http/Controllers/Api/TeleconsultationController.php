<?php

namespace App\Http\Controllers\Api;

use App\Enums\SecretaryPermission;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Calls\WebRtcAnswerRequest;
use App\Http\Requests\Calls\WebRtcIceCandidateRequest;
use App\Http\Requests\Calls\WebRtcOfferRequest;
use App\Http\Requests\Teleconsultations\CancelTeleconsultationRequest;
use App\Http\Requests\Teleconsultations\CreateTeleconsultationRequest;
use App\Http\Requests\Teleconsultations\EndTeleconsultationRequest;
use App\Http\Requests\Teleconsultations\JoinTeleconsultationRequest;
use App\Http\Requests\Teleconsultations\StartTeleconsultationRequest;
use App\Http\Resources\CallEventResource;
use App\Http\Resources\CallSessionResource;
use App\Http\Resources\TeleconsultationResource;
use App\Models\Teleconsultation;
use App\Services\AuditService;
use App\Services\DelegationContextService;
use App\Services\Teleconsultations\TeleconsultationSchemaGuard;
use App\Services\Teleconsultations\TeleconsultationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class TeleconsultationController extends Controller
{
    public function __construct(
        private readonly TeleconsultationService $teleconsultationService,
        private readonly DelegationContextService $delegationContextService,
        private readonly TeleconsultationSchemaGuard $schemaGuard,
        private readonly AuditService $auditService,
    ) {}

    public function store(CreateTeleconsultationRequest $request): JsonResponse
    {
        $this->schemaGuard->ensureAvailable();
        $this->authorizeTeleconsultationCreation($request);

        $teleconsultation = $this->teleconsultationService->create(
            actor: $request->user(),
            payload: $request->validated(),
            actingDoctorUserId: $request->attributes->get('acting_doctor_user_id'),
            delegationId: $request->attributes->get('doctor_delegation')?->id,
            request: $request,
        );

        return $this->respondSuccess([
            'teleconsultation' => new TeleconsultationResource($teleconsultation),
        ], 'Teleconsultation created successfully', 201);
    }

    public function index(Request $request): JsonResponse
    {
        $this->schemaGuard->ensureAvailable();

        if (($request->user()?->role?->value ?? $request->user()?->role) === UserRole::SECRETARY->value) {
            $this->delegationContextService->assertSecretaryPermission($request, SecretaryPermission::MANAGE_APPOINTMENTS);
        }

        $teleconsultations = $this->teleconsultationService->listForUser(
            actor: $request->user(),
            filters: $request->only([
                'status',
                'appointment_id',
                'doctor_user_id',
                'patient_user_id',
                'from_utc',
                'to_utc',
            ]),
            actingDoctorUserId: $request->attributes->get('acting_doctor_user_id'),
            perPage: (int) $request->query('per_page', 20),
        );

        $this->auditService->log(
            $request->user(),
            'teleconsultations.viewed',
            Teleconsultation::class,
            ['count' => count($teleconsultations->items())],
            $request->attributes->get('acting_doctor_user_id'),
            $request->attributes->get('doctor_delegation')?->id,
            $request,
        );

        return $this->respondSuccess(
            TeleconsultationResource::collection(collect($teleconsultations->items())),
            'Teleconsultations retrieved successfully',
            200,
            ['next_cursor' => $teleconsultations->nextCursor()?->encode()],
        );
    }

    public function show(string $teleconsultationId, Request $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationAccess($request, $teleconsultation);

        $teleconsultation = $this->teleconsultationService->syncStatus($teleconsultation);

        return $this->respondSuccess([
            'teleconsultation' => new TeleconsultationResource($teleconsultation),
        ], 'Teleconsultation retrieved successfully');
    }

    public function start(string $teleconsultationId, StartTeleconsultationRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationStart($request, $teleconsultation);

        $teleconsultation = $this->teleconsultationService->start(
            teleconsultation: $teleconsultation,
            actor: $request->user(),
            payload: $request->validated(),
            actingDoctorUserId: $request->attributes->get('acting_doctor_user_id'),
            delegationId: $request->attributes->get('doctor_delegation')?->id,
            request: $request,
        );

        return $this->respondSuccess([
            'teleconsultation' => new TeleconsultationResource($teleconsultation),
        ], 'Teleconsultation started successfully');
    }

    public function join(string $teleconsultationId, JoinTeleconsultationRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationJoin($request, $teleconsultation);

        $result = $this->teleconsultationService->join(
            teleconsultation: $teleconsultation,
            actor: $request->user(),
            payload: $request->validated(),
            actingDoctorUserId: $request->attributes->get('acting_doctor_user_id'),
            delegationId: $request->attributes->get('doctor_delegation')?->id,
            request: $request,
        );

        return $this->respondSuccess([
            'teleconsultation' => new TeleconsultationResource($result['teleconsultation']),
            'call_session' => new CallSessionResource($result['call_session']),
            'rtc_configuration' => $result['rtc_configuration'],
            'self_user_id' => $result['self_user_id'],
            'remote_user_id' => $result['remote_user_id'],
            'chat' => $result['chat'],
        ], 'Teleconsultation joined successfully');
    }

    public function cancel(string $teleconsultationId, CancelTeleconsultationRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationCancel($request, $teleconsultation);

        $teleconsultation = $this->teleconsultationService->cancel(
            teleconsultation: $teleconsultation,
            actor: $request->user(),
            payload: $request->validated(),
            actingDoctorUserId: $request->attributes->get('acting_doctor_user_id'),
            delegationId: $request->attributes->get('doctor_delegation')?->id,
            request: $request,
        );

        return $this->respondSuccess([
            'teleconsultation' => new TeleconsultationResource($teleconsultation),
        ], 'Teleconsultation cancelled successfully');
    }

    public function end(string $teleconsultationId, EndTeleconsultationRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationEnd($request, $teleconsultation);

        $teleconsultation = $this->teleconsultationService->end(
            teleconsultation: $teleconsultation,
            actor: $request->user(),
            payload: $request->validated(),
            actingDoctorUserId: $request->attributes->get('acting_doctor_user_id'),
            delegationId: $request->attributes->get('doctor_delegation')?->id,
            request: $request,
        );

        return $this->respondSuccess([
            'teleconsultation' => new TeleconsultationResource($teleconsultation),
        ], 'Teleconsultation ended successfully');
    }

    public function offer(string $teleconsultationId, WebRtcOfferRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationJoin($request, $teleconsultation);

        $this->teleconsultationService->relayOffer($teleconsultation, $request->user(), $request->validated());

        return $this->respondSuccess(null, 'Offer relayed successfully');
    }

    public function answer(string $teleconsultationId, WebRtcAnswerRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationJoin($request, $teleconsultation);

        $this->teleconsultationService->relayAnswer($teleconsultation, $request->user(), $request->validated());

        return $this->respondSuccess(null, 'Answer relayed successfully');
    }

    public function ice(string $teleconsultationId, WebRtcIceCandidateRequest $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationJoin($request, $teleconsultation);

        $this->teleconsultationService->relayIceCandidate($teleconsultation, $request->user(), $request->validated());

        return $this->respondSuccess(null, 'ICE candidate relayed successfully');
    }

    public function events(string $teleconsultationId, Request $request): JsonResponse
    {
        $teleconsultation = $this->findTeleconsultation($teleconsultationId);
        $this->authorizeTeleconsultationAccess($request, $teleconsultation);

        $events = $this->teleconsultationService->listEvents(
            teleconsultation: $teleconsultation,
            limit: (int) $request->query('limit', 50),
        );

        return $this->respondSuccess([
            'events' => CallEventResource::collection(collect($events)),
        ], 'Teleconsultation events retrieved successfully');
    }

    private function findTeleconsultation(string $teleconsultationId): Teleconsultation
    {
        $this->schemaGuard->ensureAvailable();

        return Teleconsultation::query()
            ->with(['appointment', 'participants', 'currentCallSession.participants'])
            ->findOrFail($teleconsultationId);
    }

    private function authorizeTeleconsultationCreation(Request $request): void
    {
        $user = $request->user();

        if (($user->role?->value ?? $user->role) === UserRole::SECRETARY->value) {
            $this->delegationContextService->assertSecretaryPermission($request, SecretaryPermission::MANAGE_APPOINTMENTS);

            return;
        }

        $this->authorize('create', Teleconsultation::class);
    }

    private function authorizeTeleconsultationAccess(Request $request, Teleconsultation $teleconsultation): void
    {
        $user = $request->user();

        if (($user->role?->value ?? $user->role) === UserRole::SECRETARY->value) {
            $delegation = $this->delegationContextService->assertSecretaryPermission($request, SecretaryPermission::MANAGE_APPOINTMENTS);

            if ($teleconsultation->doctor_user_id !== $delegation->doctor_user_id) {
                throw new AccessDeniedHttpException('You are not allowed to access this teleconsultation.');
            }

            return;
        }

        $this->authorize('view', $teleconsultation);
    }

    private function authorizeTeleconsultationStart(Request $request, Teleconsultation $teleconsultation): void
    {
        if (($request->user()?->role?->value ?? $request->user()?->role) === UserRole::SECRETARY->value) {
            throw new AccessDeniedHttpException('Secretaries cannot start teleconsultation media sessions.');
        }

        $this->authorize('start', $teleconsultation);
    }

    private function authorizeTeleconsultationJoin(Request $request, Teleconsultation $teleconsultation): void
    {
        if (($request->user()?->role?->value ?? $request->user()?->role) === UserRole::SECRETARY->value) {
            throw new AccessDeniedHttpException('Secretaries cannot join teleconsultation media sessions.');
        }

        $this->authorize('join', $teleconsultation);
    }

    private function authorizeTeleconsultationCancel(Request $request, Teleconsultation $teleconsultation): void
    {
        $user = $request->user();

        if (($user->role?->value ?? $user->role) === UserRole::SECRETARY->value) {
            $delegation = $this->delegationContextService->assertSecretaryPermission($request, SecretaryPermission::MANAGE_APPOINTMENTS);

            if ($teleconsultation->doctor_user_id !== $delegation->doctor_user_id) {
                throw new AccessDeniedHttpException('You are not allowed to cancel this teleconsultation.');
            }

            return;
        }

        $this->authorize('cancel', $teleconsultation);
    }

    private function authorizeTeleconsultationEnd(Request $request, Teleconsultation $teleconsultation): void
    {
        if (($request->user()?->role?->value ?? $request->user()?->role) === UserRole::SECRETARY->value) {
            throw new AccessDeniedHttpException('Secretaries cannot end teleconsultation media sessions.');
        }

        $this->authorize('end', $teleconsultation);
    }
}
