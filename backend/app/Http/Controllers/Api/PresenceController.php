<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Services\Conversations\ConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PresenceController extends Controller
{
    public function __construct(private readonly ConversationService $conversationService) {}

    public function show(string $conversationId, Request $request): JsonResponse
    {
        $conversation = Conversation::query()->findOrFail($conversationId);
        $this->authorize('view', $conversation);

        $this->conversationService->touchPresence($conversation, $request->user());

        return $this->respondSuccess([
            'conversation_id' => $conversation->id,
            'participants' => $this->conversationService->presenceSummary($conversation),
        ], 'Presence retrieved successfully');
    }
}
