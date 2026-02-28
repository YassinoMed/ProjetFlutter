<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use Illuminate\Http\Request;

class ChatMonitorController extends Controller
{
    public function index(Request $request)
    {
        $query = ChatMessage::with(['sender', 'recipient', 'consultation'])
            ->active();

        // Filter flagged messages (containing forbidden words – placeholder logic)
        if ($request->boolean('flagged_only')) {
            $query->where('is_flagged', true);
        }

        // Search by content is not possible (E2EE), so search by sender/recipient
        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->whereHas('sender', function ($sq) use ($search) {
                    $sq->where('first_name', 'LIKE', "%{$search}%")
                       ->orWhere('last_name', 'LIKE', "%{$search}%")
                       ->orWhere('email', 'LIKE', "%{$search}%");
                });
            });
        }

        $messages = $query->orderByDesc('sent_at_utc')->paginate(20);

        $stats = [
            'total_today' => ChatMessage::whereDate('sent_at_utc', today())->count(),
            'total_week'  => ChatMessage::where('sent_at_utc', '>=', now()->subWeek())->count(),
            'active_consultations' => ChatMessage::where('sent_at_utc', '>=', now()->subDay())
                                        ->distinct('consultation_id')->count('consultation_id'),
        ];

        return view('admin.chat.index', compact('messages', 'stats'));
    }
}
