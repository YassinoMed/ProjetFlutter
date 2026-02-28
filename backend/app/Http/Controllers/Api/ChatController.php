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

        return $this->respondSuccess(
            ChatMessageResource::collection(collect($messages->items())),
            'Chat messages retrieved successfully',
            200,
            ['next_cursor' => $messages->nextCursor()?->encode()]
        );
    }

    public function store(string $appointmentId, StoreChatMessageRequest $request): JsonResponse
    {
        $appointment = Appointment::query()->findOrFail($appointmentId);

        $this->authorize('view', $appointment);

        $message = $this->service->sendMessage($appointment, $request->user(), $request->validated());

        $message->load(['statuses' => fn ($q) => $q->where('user_id', $request->user()->id)]);

        return $this->respondSuccess([
            'message' => new ChatMessageResource($message),
        ], 'Message sent successfully', 201);
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

        return $this->respondSuccess([
            'status' => $entry->status->value,
            'status_at_utc' => $entry->status_at_utc->setTimezone('UTC')->toISOString(),
        ], 'Message acknowledged successfully');
    }
}
