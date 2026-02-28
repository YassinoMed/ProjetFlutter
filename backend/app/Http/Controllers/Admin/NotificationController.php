<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FcmToken;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $query = FcmToken::with('user');

        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('first_name', 'LIKE', "%{$search}%")
                  ->orWhere('last_name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $tokens = $query->orderByDesc('updated_at')->paginate(15);

        $stats = [
            'total_devices' => FcmToken::count(),
            'active_today' => FcmToken::where('last_seen_at_utc', '>=', now()->subDay())->count(),
            'unique_users' => FcmToken::distinct('user_id')->count('user_id'),
        ];

        return view('admin.notifications.index', compact('tokens', 'stats'));
    }
}
