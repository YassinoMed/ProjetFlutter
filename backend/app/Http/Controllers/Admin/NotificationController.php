<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\SearchesUsers;
use App\Http\Controllers\Controller;
use App\Models\FcmToken;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use SearchesUsers;

    public function index(Request $request)
    {
        $query = FcmToken::with('user');

        // Refactored: use shared trait for user search via relation
        if ($request->filled('search')) {
            $this->applyRelatedUserSearch($query, 'user', $request->input('search'));
        }

        $tokens = $query->orderByDesc('updated_at')->paginate(15);

        $stats = [
            'total_devices' => FcmToken::count(),
            'active_today'  => FcmToken::where('last_seen_at_utc', '>=', now()->subDay())->count(),
            'unique_users'  => FcmToken::distinct('user_id')->count('user_id'),
        ];

        return view('admin.notifications.index', compact('tokens', 'stats'));
    }
}
