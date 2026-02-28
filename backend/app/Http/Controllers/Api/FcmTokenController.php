<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Fcm\UpsertFcmTokenRequest;
use App\Models\FcmToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FcmTokenController extends Controller
{
    public function upsert(UpsertFcmTokenRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();

        $token = FcmToken::query()->updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $user->id,
                'platform' => $data['platform'] ?? null,
                'last_seen_at_utc' => now('UTC'),
            ],
        );

        return $this->respondSuccess([
            'id' => $token->id,
        ], 'Token upserted successfully');
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        $deleted = FcmToken::query()
            ->where('user_id', $request->user()->id)
            ->where('token', $request->string('token'))
            ->delete();

        return $this->respondSuccess([
            'deleted' => $deleted,
        ], 'Token deleted successfully');
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string', 'max:512'],
        ]);

        $updated = FcmToken::query()
            ->where('user_id', $request->user()->id)
            ->where('token', $request->string('token'))
            ->update(['last_seen_at_utc' => now('UTC')]);

        return $this->respondSuccess([
            'updated' => $updated,
        ], 'Heartbeat updated successfully');
    }
}
