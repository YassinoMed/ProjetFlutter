<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Conversations\CreateConversationRequest;
use App\Http\Resources\ConversationResource;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\Message;
use App\Services\Conversations\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    public function __construct(private readonly ConversationService $conversationService) {}

    public function index(Request $request): JsonResponse
    {
        $perPage = min(max((int) $request->query('per_page', 20), 1), 50);
        $conversations = $this->conversationService->listForUser($request->user(), $perPage);

        return $this->respondSuccess(
            ConversationResource::collection(collect($conversations->items())),
            'Conversations retrieved successfully',
            200,
            ['next_cursor' => $conversations->nextCursor()?->encode()],
        );
    }

    public function store(CreateConversationRequest $request): JsonResponse
    {
        $conversation = $this->conversationService->createOrFind($request->user(), $request->validated());

        return $this->respondSuccess(
            new ConversationResource($conversation->load('participants')),
            'Conversation ready',
            201,
        );
    }

    public function show(string $conversationId, Request $request): JsonResponse
    {
        $conversation = Conversation::query()->with('participants')->findOrFail($conversationId);

        $this->authorize('view', $conversation);
        $this->conversationService->touchPresence($conversation, $request->user());

        return $this->respondSuccess(
            new ConversationResource($conversation),
            'Conversation retrieved successfully',
        );
    }

    public function messages(string $conversationId, Request $request): JsonResponse
    {
        $conversation = Conversation::query()->findOrFail($conversationId);

        $this->authorize('view', $conversation);
        $this->conversationService->touchPresence($conversation, $request->user());

        $perPage = min(max((int) $request->query('per_page', 50), 1), 100);
        $query = Message::query()
            ->where('conversation_id', $conversation->id)
            ->with('receipts')
            ->orderByDesc('sent_at_utc');

        if ($request->filled('after_sent_at_utc')) {
            $query->where('sent_at_utc', '>', $request->date('after_sent_at_utc'));
        }

        $messages = $query->cursorPaginate($perPage);

        return $this->respondSuccess(
            MessageResource::collection(collect($messages->items())),
            'Messages retrieved successfully',
            200,
            ['next_cursor' => $messages->nextCursor()?->encode()],
        );
    }
}
