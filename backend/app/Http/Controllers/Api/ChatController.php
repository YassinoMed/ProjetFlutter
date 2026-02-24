<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Chat\AckChatMessageRequest;
use App\Http\Requests\Chat\StoreChatMessageRequest;
use App\Http\Resources\ChatMessageResource;
use App\Models\Appointment;
use App\Models\ChatMessage;
use App\Services\Chat\ChatMessageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function __construct(private readonly ChatMessageService $service) {}

    public function index(string $appointmentId, Request $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $perPage = min(max((int) $request->query('per_page', 50), 1), 50);

        $messages = ChatMessage::query()
            ->where('consultation_id', $appointment->id)
            ->orderByDesc('sent_at_utc')
            ->with([
                'statuses' => fn ($q) => $q->where('user_id', $request->user()->id),
            ])
            ->cursorPaginate($perPage);

        return response()->json([
            'data' => ChatMessageResource::collection(collect($messages->items())),
            'next_cursor' => $messages->nextCursor()?->encode(),
        ]);
    }

    public function store(string $appointmentId, StoreChatMessageRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $message = $this->service->sendMessage($appointment, $request->user(), $request->validated());

        $message->load(['statuses' => fn ($q) => $q->where('user_id', $request->user()->id)]);

        return response()->json([
            'message' => new ChatMessageResource($message),
        ], 201);
    }

    public function ack(string $appointmentId, string $messageId, AckChatMessageRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $message = ChatMessage::query()
            ->where('consultation_id', $appointment->id)
            ->where('id', $messageId)
            ->firstOrFail();

        $entry = $this->service->acknowledge($message, $request->user(), $request->validated()['status']);

        return response()->json([
            'ok' => true,
            'status' => $entry->status->value,
            'status_at_utc' => $entry->status_at_utc->setTimezone('UTC')->toISOString(),
        ]);
    }
}
