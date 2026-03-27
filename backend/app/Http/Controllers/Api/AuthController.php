<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\DisableBiometricRequest;
use App\Http\Requests\Auth\EnableBiometricRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\Doctor;
use App\Models\TrustedDevice;
use App\Models\User;
use App\Services\AuditService;
use App\Services\Auth\AuthTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthTokenService $tokens,
        private readonly AuditService $audit,
    ) {}

    /**
     * POST /api/auth/register
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();

        $roleInput = strtoupper((string) ($data['role'] ?? UserRole::PATIENT->value));
        $role = UserRole::tryFrom($roleInput) ?? UserRole::PATIENT;

        $user = User::query()->create([
            'email' => strtolower($data['email']),
            'password' => $data['password'],
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'phone' => $this->normalizePhone($data['phone'] ?? null),
            'role' => $role,
        ]);

        if ($role === UserRole::DOCTOR) {
            Doctor::query()->create([
                'user_id' => $user->id,
                'specialty' => $data['speciality'] ?? null,
                'rpps' => $data['license_number'] ?? null,
            ]);
        }

        // Issue Sanctum token
        $tokenData = $this->tokens->issueForUser($user, $request);

        // Register trusted device
        $device = $this->registerDevice($user, $request);

        $this->audit->log(
            actor: $user,
            event: 'auth.register',
            auditable: $device ?? $user,
            context: [
                'device_uuid' => $device?->device_id,
                'device_name' => $device?->device_name,
                'platform' => $device?->platform,
            ],
            request: $request,
        );

        return $this->respondSuccess([
            'user' => new UserResource($user),
            'token' => $tokenData['token'],
        ], 'Registration successful', 201);
    }

    /**
     * POST /api/auth/login
     *
     * Authenticate with email + password.
     * Issues a new Sanctum personal access token per session.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $data = $request->validated();
        $login = trim((string) ($data['login'] ?? ''));

        $user = $this->resolveUserForLogin($login);

        if ($user === null || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['Invalid credentials'],
            ]);
        }

        // Issue Sanctum token (named after device_name for revocation tracking)
        $tokenData = $this->tokens->issueForUser($user, $request);

        // Register/update trusted device
        $device = $this->registerDevice($user, $request);

        $this->audit->log(
            actor: $user,
            event: 'auth.login',
            auditable: $device ?? $user,
            context: [
                'device_uuid' => $device?->device_id,
                'device_name' => $device?->device_name,
                'platform' => $device?->platform,
                'token_name' => $tokenData['token_name'] ?? null,
            ],
            request: $request,
        );

        return $this->respondSuccess([
            'user' => new UserResource($user),
            'token' => $tokenData['token'],
            'device_approved' => $device !== null,
        ], 'Login successful');
    }

    /**
     * POST /api/auth/logout
     *
     * Revokes the current Sanctum token only.
     * The user remains logged in on other devices.
     */
    public function logout(Request $request): JsonResponse
    {
        /** @var User|null $user */
        $user = $request->user();
        $currentTokenName = $user?->currentAccessToken()?->name;

        $this->tokens->logout($request);

        if ($user !== null) {
            $this->audit->log(
                actor: $user,
                event: 'auth.logout',
                auditable: TrustedDevice::class,
                context: [
                    'token_name' => $currentTokenName,
                ],
                request: $request,
            );
        }

        return $this->respondSuccess(null, 'Logged out successfully');
    }

    /**
     * GET /api/auth/me
     */
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return $this->respondSuccess([
            'user' => new UserResource($user),
        ], 'User profile retrieved');
    }

    /**
     * POST /api/auth/enable-biometric
     *
     * Marks the given device as biometrics-enabled.
     * IMPORTANT: No fingerprint data is received or stored.
     * The Flutter client has already verified the fingerprint locally.
     */
    public function enableBiometric(EnableBiometricRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $data = $request->validated();

        $device = TrustedDevice::query()
            ->where('user_id', $user->id)
            ->where('device_id', $data['device_id'])
            ->active()
            ->first();

        if ($device === null) {
            $device = TrustedDevice::query()->create([
                'user_id' => $user->id,
                'device_id' => $data['device_id'],
                'device_name' => $data['device_name'],
                'platform' => $data['platform'] ?? 'unknown',
                'biometrics_enabled' => true,
                'last_login_at' => now(),
            ]);
        } else {
            $device->update([
                'biometrics_enabled' => true,
                'device_name' => $data['device_name'],
                'platform' => $data['platform'] ?? $device->platform,
            ]);
        }

        $this->audit->log(
            actor: $user,
            event: 'auth.biometric.enabled',
            auditable: $device,
            context: [
                'device_uuid' => $device->device_id,
                'platform' => $device->platform,
            ],
            request: $request,
        );

        return $this->respondSuccess([
            'device_uuid' => $device->device_id,
            'device_id' => $device->device_id,
            'biometrics_enabled' => true,
        ], 'Biometric authentication enabled for this device');
    }

    /**
     * POST /api/auth/disable-biometric
     */
    public function disableBiometric(DisableBiometricRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $data = $request->validated();

        $device = TrustedDevice::query()
            ->where('user_id', $user->id)
            ->where('device_id', $data['device_id'])
            ->active()
            ->first();

        if ($device === null) {
            return $this->respondError('Device not found', 404);
        }

        $device->update(['biometrics_enabled' => false]);

        $this->audit->log(
            actor: $user,
            event: 'auth.biometric.disabled',
            auditable: $device,
            context: [
                'device_uuid' => $device->device_id,
                'platform' => $device->platform,
            ],
            request: $request,
        );

        return $this->respondSuccess([
            'device_uuid' => $device->device_id,
            'device_id' => $device->device_id,
            'biometrics_enabled' => false,
        ], 'Biometric authentication disabled for this device');
    }

    // ── Private Helpers ──────────────────────────────────────

    /**
     * Register or update a trusted device on login/register.
     */
    private function registerDevice(User $user, Request $request): ?TrustedDevice
    {
        $deviceId = $request->input('device_id', $request->input('device_uuid'));
        if (empty($deviceId)) {
            return null;
        }

        $deviceName = $request->input('device_name', 'Unknown Device');
        $platform = $request->input('platform', 'unknown');

        return TrustedDevice::query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'device_id' => $deviceId,
            ],
            [
                'device_name' => $deviceName,
                'platform' => $platform,
                'last_login_at' => now(),
                'revoked_at' => null, // Re-activate if previously revoked
            ]
        );
    }

    private function resolveUserForLogin(string $login): ?User
    {
        if ($login === '') {
            return null;
        }

        if (filter_var($login, FILTER_VALIDATE_EMAIL)) {
            return User::query()
                ->where('email', strtolower($login))
                ->first();
        }

        $normalizedPhone = $this->normalizePhone($login);
        $candidates = array_values(array_unique(array_filter([$login, $normalizedPhone])));

        if ($candidates === []) {
            return null;
        }

        return User::query()
            ->whereIn('phone', $candidates)
            ->first();
    }

    private function normalizePhone(?string $phone): ?string
    {
        if ($phone === null) {
            return null;
        }

        $normalized = preg_replace('/(?!^\+)[^\d]/', '', trim($phone));

        return $normalized !== '' ? $normalized : null;
    }
}
