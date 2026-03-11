<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Secretaries\SwitchDoctorContextRequest;
use App\Http\Resources\DoctorSecretaryDelegationResource;
use App\Services\AuditService;
use App\Services\DoctorSecretaries\DoctorSecretaryService;
use Illuminate\Http\JsonResponse;

class DelegationContextController extends Controller
{
    public function __construct(
        private readonly DoctorSecretaryService $doctorSecretaryService,
        private readonly AuditService $auditService,
    ) {}

    public function switchDoctor(SwitchDoctorContextRequest $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== UserRole::SECRETARY) {
            return $this->respondError('Only secretaries can switch doctor context.', 403);
        }

        $delegation = $this->doctorSecretaryService->assertActiveDelegation(
            $user,
            $request->validated()['doctor_user_id'],
        );

        $this->doctorSecretaryService->touchDelegationUsage($delegation);
        $this->auditService->log(
            $user,
            'secretary.context.switched',
            $delegation,
            ['doctor_user_id' => $delegation->doctor_user_id],
            actingDoctorUserId: $delegation->doctor_user_id,
            delegationId: $delegation->id,
            request: $request,
        );

        return $this->respondSuccess([
            'delegation' => new DoctorSecretaryDelegationResource($delegation),
            'acting_doctor_user_id' => $delegation->doctor_user_id,
        ], 'Doctor context validated successfully');
    }
}
