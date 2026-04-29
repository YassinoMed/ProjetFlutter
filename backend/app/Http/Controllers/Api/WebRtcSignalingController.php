<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Calls\WebRtcAnswerRequest;
use App\Http\Requests\Calls\WebRtcIceCandidateRequest;
use App\Http\Requests\Calls\WebRtcOfferRequest;
use App\Models\CallSession;
use App\Services\Calls\CallSessionService;
use Illuminate\Http\JsonResponse;

class WebRtcSignalingController extends Controller
{
    public function __construct(private readonly CallSessionService $callSessionService) {}

    public function offer(string $callSessionId, WebRtcOfferRequest $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('signal', $callSession);

        $this->callSessionService->relayOffer($callSession, $request->user(), $request->validated());

        return $this->respondSuccess(null, 'Offer relayed successfully');
    }

    public function answer(string $callSessionId, WebRtcAnswerRequest $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('signal', $callSession);

        $this->callSessionService->relayAnswer($callSession, $request->user(), $request->validated());

        return $this->respondSuccess(null, 'Answer relayed successfully');
    }

    public function ice(string $callSessionId, WebRtcIceCandidateRequest $request): JsonResponse
    {
        $callSession = CallSession::query()->findOrFail($callSessionId);
        $this->authorize('signal', $callSession);

        $this->callSessionService->relayIceCandidate($callSession, $request->user(), $request->validated());

        return $this->respondSuccess(null, 'ICE candidate relayed successfully');
    }
}
