<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Calls\InitiateCallRequest;
use App\Http\Resources\CallSessionResource;
use App\Models\CallSession;
use App\Services\Calls\CallSessionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CallSessionController extends Controller
{
    public function __construct(private readonly CallSessionService $callSessionService) {}

    public function show(string $callSessionId, Request $request): JsonResponse
    {
        $callSession = CallSession::query()->with('participants')->findOrFail($callSessionId);
        $this->authorize('view', $callSession);

        return $this->respondSuccess(
            new CallSessionResource($callSession),
            'Call session retrieved successfully',
        );
    }

    public function initiate(InitiateCallRequest $request): JsonResponse
    {
        $callSession = $this->callSessionService->initiate($request->user(), $request->validated());

        return $this->respondSuccess(
            ['call_session' => new CallSessionResource($callSession)],
            'Call initiated successfully',
            201,
        );
    }

    public function accept(string $callSessionId, Request $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('view', $callSession);

        $callSession = $this->callSessionService->accept($callSession, $request->user());

        return $this->respondSuccess(
            ['call_session' => new CallSessionResource($callSession)],
            'Call accepted successfully',
        );
    }

    public function reject(string $callSessionId, Request $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('view', $callSession);

        $callSession = $this->callSessionService->reject($callSession, $request->user());

        return $this->respondSuccess(
            ['call_session' => new CallSessionResource($callSession)],
            'Call rejected successfully',
        );
    }

    public function cancel(string $callSessionId, Request $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('view', $callSession);

        $callSession = $this->callSessionService->cancel($callSession, $request->user());

        return $this->respondSuccess(
            ['call_session' => new CallSessionResource($callSession)],
            'Call cancelled successfully',
        );
    }

    public function end(string $callSessionId, Request $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('view', $callSession);

        $callSession = $this->callSessionService->end($callSession, $request->user());

        return $this->respondSuccess(
            ['call_session' => new CallSessionResource($callSession)],
            'Call ended successfully',
        );
    }
}
