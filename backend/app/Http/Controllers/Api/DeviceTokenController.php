<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Devices\RegisterDeviceTokenRequest;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    public function register(RegisterDeviceTokenRequest $request): JsonResponse
    {
        $token = DeviceToken::query()->updateOrCreate(
            ['token' => $request->validated()['token']],
            [
                'user_id' => $request->user()->id,
                'provider' => $request->validated()['provider'],
                'platform' => $request->validated()['platform'] ?? null,
                'device_label' => $request->validated()['device_label'] ?? null,
                'last_seen_at_utc' => now('UTC'),
                'revoked_at' => null,
            ],
        );

        return $this->respondSuccess([
            'device_token_id' => $token->id,
        ], 'Push token registered successfully');
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        $updated = DeviceToken::query()
            ->where('user_id', $request->user()->id)
            ->where('token', $request->string('token'))
            ->update(['last_seen_at_utc' => now('UTC')]);

        return $this->respondSuccess([
            'updated' => $updated,
        ], 'Push token heartbeat updated');
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        $updated = DeviceToken::query()
            ->where('user_id', $request->user()->id)
            ->where('token', $request->string('token'))
            ->update(['revoked_at' => now('UTC')]);

        return $this->respondSuccess([
            'revoked' => $updated,
        ], 'Push token revoked successfully');
    }
}
