<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TrustedDevice;
use App\Services\AuditService;
use App\Services\Auth\AuthTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;

/**
 * DeviceController — manage trusted devices for a user.
 *
 * When a device is revoked, all Sanctum tokens associated with
 * that device_name are also deleted. This ensures the lost/stolen
 * device can no longer make authenticated requests.
 */
class DeviceController extends Controller
{
    public function __construct(
        private readonly AuthTokenService $tokens,
        private readonly AuditService $audit,
    ) {}

    /**
     * GET /api/auth/devices
     */
    public function index(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();
        $currentTokenName = $user->currentAccessToken()?->name;

        $devices = TrustedDevice::query()
            ->where('user_id', $user->id)
            ->active()
            ->orderByDesc('last_login_at')
            ->get()
            ->map(fn (TrustedDevice $d) => [
                'id' => $d->id,
                'device_uuid' => $d->device_id,
                'device_id' => $d->device_id,
                'device_name' => $d->device_name,
                'platform' => $d->platform,
                'biometrics_enabled' => $d->biometrics_enabled,
                'last_used_at' => $d->last_login_at?->toISOString(),
                'last_login_at' => $d->last_login_at?->toISOString(),
                'current_device' => in_array($currentTokenName, [$d->device_id, $d->device_name], true),
                'created_at' => $d->created_at?->toISOString(),
            ]);

        return $this->respondSuccess($devices, 'Devices retrieved');
    }

    /**
     * DELETE /api/auth/devices/{deviceId}
     *
     * Revoke a trusted device:
     * 1. Mark TrustedDevice as revoked (revoked_at timestamp)
     * 2. Delete all Sanctum tokens named after this device
     *    → the lost/stolen phone will get 401 on next request
     */
    public function destroy(Request $request, string $deviceId): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();
        $currentTokenName = $user->currentAccessToken()?->name;
        $currentTokenId = $user->currentAccessToken()?->id;

        $device = TrustedDevice::query()
            ->where('user_id', $user->id)
            ->where('id', $deviceId)
            ->active()
            ->first();

        if ($device === null) {
            return $this->respondError('Appareil non trouvé ou déjà révoqué', 404);
        }

        $currentDeviceRevoked = in_array($currentTokenName, [$device->device_id, $device->device_name], true);

        // Revoke the device record
        $device->revoke();

        // Delete all Sanctum tokens issued for this logical device
        $this->tokens->revokeTokensForDevice($user, $device->device_id, $device->device_name);

        if ($currentDeviceRevoked && $currentTokenId !== null) {
            PersonalAccessToken::query()->whereKey($currentTokenId)->delete();
        }

        $this->audit->log(
            actor: $user,
            event: 'auth.device.revoked',
            auditable: $device,
            context: [
                'device_uuid' => $device->device_id,
                'device_name' => $device->device_name,
                'platform' => $device->platform,
                'current_device_revoked' => $currentDeviceRevoked,
            ],
            request: $request,
        );

        return $this->respondSuccess([
            'current_device_revoked' => $currentDeviceRevoked,
        ], 'Appareil révoqué avec succès');
    }
}
