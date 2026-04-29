<?php

namespace App\Http\Controllers\Api;

use App\Enums\MessageReceiptStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Messages\StoreMessageRequest;
use App\Http\Requests\Messages\TypingIndicatorRequest;
use App\Http\Requests\Messages\UpdateMessageReceiptRequest;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\Message;
use App\Services\Messages\MessageService;
use Illuminate\Http\JsonResponse;

class MessageController extends Controller
{
    public function __construct(private readonly MessageService $messageService) {}

    public function store(StoreMessageRequest $request): JsonResponse
    {
        $message = $this->messageService->send($request->user(), $request->validated());

        return $this->respondSuccess(
            ['message' => new MessageResource($message)],
            'Message sent successfully',
            201,
        );
    }

    public function delivered(string $messageId, UpdateMessageReceiptRequest $request): JsonResponse
    {
        $message = Message::query()->findOrFail($messageId);
        $this->authorize('view', $message);

        $receipt = $this->messageService->updateReceipt($message, $request->user(), MessageReceiptStatus::DELIVERED);

        return $this->respondSuccess([
            'message_id' => $message->id,
            'status' => $receipt->status?->value ?? $receipt->status,
            'status_at_utc' => optional($receipt->status_at_utc)?->setTimezone('UTC')?->toISOString(),
        ], 'Message marked as delivered');
    }

    public function read(string $messageId, UpdateMessageReceiptRequest $request): JsonResponse
    {
        $message = Message::query()->findOrFail($messageId);
        $this->authorize('view', $message);

        $receipt = $this->messageService->updateReceipt($message, $request->user(), MessageReceiptStatus::READ);

        return $this->respondSuccess([
            'message_id' => $message->id,
            'status' => $receipt->status?->value ?? $receipt->status,
            'status_at_utc' => optional($receipt->status_at_utc)?->setTimezone('UTC')?->toISOString(),
        ], 'Message marked as read');
    }

    public function typing(string $conversationId, TypingIndicatorRequest $request): JsonResponse
    {
        $conversation = Conversation::query()->findOrFail($conversationId);
        $this->authorize('view', $conversation);

        $this->messageService->broadcastTyping(
            $conversation,
            $request->user(),
            (bool) $request->validated()['is_typing'],
        );

        return $this->respondSuccess(null, 'Typing indicator broadcasted');
    }
}
