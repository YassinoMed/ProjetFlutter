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

        return response()->json([
            'ok' => true,
            'id' => $token->id,
        ]);
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

        return response()->json([
            'ok' => true,
            'deleted' => $deleted,
        ]);
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

        return response()->json([
            'ok' => true,
            'updated' => $updated,
        ]);
    }
}
