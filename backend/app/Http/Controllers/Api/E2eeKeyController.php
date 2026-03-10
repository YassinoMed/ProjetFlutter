<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\E2ee\UpsertE2eeDeviceRequest;
use App\Models\User;
use App\Services\E2ee\E2eeKeyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class E2eeKeyController extends Controller
{
    public function __construct(private readonly E2eeKeyService $e2eeKeyService) {}

    public function upsertOwnDevice(UpsertE2eeDeviceRequest $request): JsonResponse
    {
        $device = $this->e2eeKeyService->upsertOwnDevice($request->user(), $request->validated());

        return $this->respondSuccess([
            'device_id' => $device->device_id,
            'bundle_version' => $device->bundle_version,
            'pre_keys_count' => $device->preKeys->count(),
        ], 'E2EE device bundle upserted successfully');
    }

    public function showPeerBundle(string $userId, Request $request): JsonResponse
    {
        $peer = User::query()->findOrFail($userId);

        $bundle = $this->e2eeKeyService->getPeerBundle(
            $request->user(),
            $peer,
            $request->query('consultation_id'),
        );

        return $this->respondSuccess($bundle, 'E2EE bundle retrieved successfully');
    }
}
