<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Secretaries\AcceptSecretaryInvitationRequest;
use App\Http\Resources\DoctorSecretaryDelegationResource;
use App\Services\DoctorSecretaries\DoctorSecretaryService;
use Illuminate\Http\JsonResponse;

class SecretaryInvitationController extends Controller
{
    public function __construct(private readonly DoctorSecretaryService $doctorSecretaryService) {}

    public function accept(AcceptSecretaryInvitationRequest $request): JsonResponse
    {
        $delegation = $this->doctorSecretaryService->acceptInvitation($request->validated());

        return $this->respondSuccess([
            'delegation' => new DoctorSecretaryDelegationResource($delegation),
        ], 'Secretary invitation accepted successfully');
    }
}
