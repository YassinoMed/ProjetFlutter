<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RefreshRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Auth\AuthTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(private readonly AuthTokenService $tokens) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();

        $user = User::query()->create([
            'email' => strtolower($data['email']),
            'password' => $data['password'],
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'phone' => $data['phone'] ?? null,
            'role' => UserRole::PATIENT,
        ]);

        $tokens = $this->tokens->issueForUser($user, $request);

        return $this->respondSuccess([
            'user' => new UserResource($user),
            'tokens' => $tokens,
        ], 'Registration successful', 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $data = $request->validated();

        $user = User::query()->where('email', strtolower($data['email']))->first();

        if ($user === null || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        $tokens = $this->tokens->issueForUser($user, $request);

        return $this->respondSuccess([
            'user' => new UserResource($user),
            'tokens' => $tokens,
        ], 'Login successful');
    }

    public function refresh(RefreshRequest $request): JsonResponse
    {
        $data = $request->validated();

        $tokens = $this->tokens->rotateRefresh($data['refresh_token'], $request);

        return $this->respondSuccess([
            'tokens' => $tokens,
        ], 'Token refreshed');
    }

    public function logout(): JsonResponse
    {
        $this->tokens->logout(request());

        return $this->respondSuccess(null, 'Logged out completely');
    }

    public function me(): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = request()->user();

        return $this->respondSuccess([
            'user' => new UserResource($user),
        ], 'User profile retrieved');
    }
}
