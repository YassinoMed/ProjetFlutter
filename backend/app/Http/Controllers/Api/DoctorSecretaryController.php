<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Secretaries\InviteSecretaryRequest;
use App\Http\Requests\Secretaries\SuspendSecretaryRequest;
use App\Http\Requests\Secretaries\UpdateSecretaryPermissionsRequest;
use App\Http\Resources\DoctorSecretaryDelegationResource;
use App\Models\DoctorSecretaryDelegation;
use App\Services\DoctorSecretaries\DoctorSecretaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DoctorSecretaryController extends Controller
{
    public function __construct(private readonly DoctorSecretaryService $doctorSecretaryService) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', DoctorSecretaryDelegation::class);

        $delegations = $this->doctorSecretaryService->listForDoctor($request->user());

        return $this->respondSuccess(
            DoctorSecretaryDelegationResource::collection($delegations),
            'Doctor secretaries retrieved successfully',
        );
    }

    public function invite(InviteSecretaryRequest $request): JsonResponse
    {
        $this->authorize('create', DoctorSecretaryDelegation::class);

        $result = $this->doctorSecretaryService->invite($request->user(), $request->validated());

        return $this->respondSuccess([
            'delegation' => new DoctorSecretaryDelegationResource($result['delegation']),
            'invitation_token' => $result['plain_token'],
            'invitation_expires_at_utc' => optional($result['invitation']->expires_at_utc)?->setTimezone('UTC')?->toISOString(),
        ], 'Secretary invited successfully', 201);
    }

    public function updatePermissions(string $delegationId, UpdateSecretaryPermissionsRequest $request): JsonResponse
    {
        $delegation = DoctorSecretaryDelegation::query()->findOrFail($delegationId);
        $this->authorize('update', $delegation);

        $delegation = $this->doctorSecretaryService->updatePermissions(
            $request->user(),
            $delegation,
            $request->validated()['permissions'],
        );

        return $this->respondSuccess([
            'delegation' => new DoctorSecretaryDelegationResource($delegation),
        ], 'Secretary permissions updated successfully');
    }

    public function suspend(string $delegationId, SuspendSecretaryRequest $request): JsonResponse
    {
        $delegation = DoctorSecretaryDelegation::query()->findOrFail($delegationId);
        $this->authorize('update', $delegation);
        $delegation = $this->doctorSecretaryService->suspend($request->user(), $delegation, $request->validated()['reason'] ?? null);

        return $this->respondSuccess([
            'delegation' => new DoctorSecretaryDelegationResource($delegation),
        ], 'Secretary suspended successfully');
    }

    public function reactivate(string $delegationId, Request $request): JsonResponse
    {
        $delegation = DoctorSecretaryDelegation::query()->findOrFail($delegationId);
        $this->authorize('update', $delegation);
        $delegation = $this->doctorSecretaryService->reactivate($request->user(), $delegation);

        return $this->respondSuccess([
            'delegation' => new DoctorSecretaryDelegationResource($delegation),
        ], 'Secretary reactivated successfully');
    }

    public function destroy(string $delegationId, Request $request): JsonResponse
    {
        $delegation = DoctorSecretaryDelegation::query()->findOrFail($delegationId);
        $this->authorize('delete', $delegation);
        $this->doctorSecretaryService->revoke($request->user(), $delegation);

        return $this->respondSuccess(null, 'Secretary access revoked successfully');
    }
}
