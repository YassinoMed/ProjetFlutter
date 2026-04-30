<?php

namespace App\Http\Controllers\Api;

use App\Events\ConsultationJoined;
use App\Events\WebRtcAnswerSent;
use App\Events\WebRtcIceCandidateSent;
use App\Events\WebRtcOfferSent;
use App\Http\Controllers\Controller;
use App\Http\Requests\WebRtc\WebRtcAnswerRequest;
use App\Http\Requests\WebRtc\WebRtcIceCandidateRequest;
use App\Http\Requests\WebRtc\WebRtcOfferRequest;
use App\Models\Appointment;
use App\Services\WebRtc\IceServerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WebRtcController extends Controller
{
    public function iceServers(Request $request, IceServerService $iceServerService): JsonResponse
    {
        return $this->respondSuccess(
            $iceServerService->forUser($request->user()),
            'ICE servers retrieved successfully',
        );
    }

    public function join(string $appointmentId, Request $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $event = new ConsultationJoined(
            $appointment->id,
            $request->user()->id,
            now('UTC')->toISOString(),
        );

        event($event);

        return $this->respondSuccess(null, 'Joined successfully');
    }

    public function offer(string $appointmentId, WebRtcOfferRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $payload = $request->validated();

        event(new WebRtcOfferSent(
            $appointment->id,
            $request->user()->id,
            $payload['sdp'],
            $payload['sdp_type'],
            now('UTC')->toISOString(),
        ));

        return $this->respondSuccess(null, 'Offer sent successfully');
    }

    public function answer(string $appointmentId, WebRtcAnswerRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $payload = $request->validated();

        event(new WebRtcAnswerSent(
            $appointment->id,
            $request->user()->id,
            $payload['sdp'],
            $payload['sdp_type'],
            now('UTC')->toISOString(),
        ));

        return $this->respondSuccess(null, 'Answer sent successfully');
    }

    public function ice(string $appointmentId, WebRtcIceCandidateRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $payload = $request->validated();

        event(new WebRtcIceCandidateSent(
            $appointment->id,
            $request->user()->id,
            $payload['candidate'],
            $payload['sdp_mid'] ?? null,
            $payload['sdp_mline_index'] ?? null,
            now('UTC')->toISOString(),
        ));

        return $this->respondSuccess(null, 'ICE candidate sent successfully');
    }
}
