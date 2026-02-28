<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\SearchesUsers;
use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use Illuminate\Http\Request;

class ChatMonitorController extends Controller
{
    use SearchesUsers;

    public function index(Request $request)
    {
        $query = ChatMessage::with(['sender', 'recipient', 'consultation'])
            ->active();

        if ($request->boolean('flagged_only')) {
            $query->where('is_flagged', true);
        }

        // Refactored: use shared trait for user search via relation
        if ($request->filled('search')) {
            $this->applyRelatedUserSearch($query, 'sender', $request->input('search'));
        }

        $messages = $query->orderByDesc('sent_at_utc')->paginate(20);

        $stats = [
            'total_today'          => ChatMessage::whereDate('sent_at_utc', today())->count(),
            'total_week'           => ChatMessage::where('sent_at_utc', '>=', now()->subWeek())->count(),
            'active_consultations' => ChatMessage::where('sent_at_utc', '>=', now()->subDay())
                                        ->distinct('consultation_id')->count('consultation_id'),
        ];

        return view('admin.chat.index', compact('messages', 'stats'));
    }
}
