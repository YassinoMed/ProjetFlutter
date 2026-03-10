<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TrustedDevice;
use App\Services\Auth\AuthTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * DeviceController — manage trusted devices for a user.
 *
 * When a device is revoked, all Sanctum tokens associated with
 * that device_name are also deleted. This ensures the lost/stolen
 * device can no longer make authenticated requests.
 */
class DeviceController extends Controller
{
    public function __construct(private readonly AuthTokenService $tokens) {}

    /**
     * GET /api/auth/devices
     */
    public function index(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        $devices = TrustedDevice::query()
            ->where('user_id', $user->id)
            ->active()
            ->orderByDesc('last_login_at')
            ->get()
            ->map(fn (TrustedDevice $d) => [
                'id'                 => $d->id,
                'device_id'          => $d->device_id,
                'device_name'        => $d->device_name,
                'platform'           => $d->platform,
                'biometrics_enabled' => $d->biometrics_enabled,
                'last_login_at'      => $d->last_login_at?->toISOString(),
                'created_at'         => $d->created_at?->toISOString(),
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

        $device = TrustedDevice::query()
            ->where('user_id', $user->id)
            ->where('id', $deviceId)
            ->active()
            ->first();

        if ($device === null) {
            return $this->respondError('Appareil non trouvé ou déjà révoqué', 404);
        }

        // Revoke the device record
        $device->revoke();

        // Delete all Sanctum tokens issued for this device_name
        $this->tokens->revokeTokensByDeviceName($user, $device->device_name);

        return $this->respondSuccess(null, 'Appareil révoqué avec succès');
    }
}
