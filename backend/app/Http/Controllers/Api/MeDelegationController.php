<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\DoctorSecretaryDelegationResource;
use App\Services\DoctorSecretaries\DoctorSecretaryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeDelegationController extends Controller
{
    public function __construct(private readonly DoctorSecretaryService $doctorSecretaryService) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== UserRole::SECRETARY) {
            return $this->respondSuccess([
                'delegations' => [],
            ], 'No delegations for this user role');
        }

        $delegations = $this->doctorSecretaryService->delegationsForSecretary($user);

        return $this->respondSuccess([
            'delegations' => DoctorSecretaryDelegationResource::collection($delegations),
        ], 'Delegations retrieved successfully');
    }
}
