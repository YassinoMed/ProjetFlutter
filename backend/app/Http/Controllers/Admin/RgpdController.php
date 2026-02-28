<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserConsent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class RgpdController extends Controller
{
    public function index(Request $request)
    {
        $query = UserConsent::with('user');

        if ($request->filled('consent_type')) {
            $query->where('consent_type', $request->input('consent_type'));
        }

        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('first_name', 'LIKE', "%{$search}%")
                  ->orWhere('last_name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $consents = $query->orderByDesc('updated_at')->paginate(15);

        $stats = [
            'total_consents' => UserConsent::where('consented', true)->count(),
            'total_revoked'  => UserConsent::where('consented', false)->count(),
            'pending_deletion_requests' => User::where('email', 'LIKE', 'deleted+%')->count(),
        ];

        return view('admin.rgpd.index', compact('consents', 'stats'));
    }

    public function anonymize(Request $request, string $userId)
    {
        $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $user = User::findOrFail($userId);

        DB::transaction(function () use ($user) {
            $user->update([
                'email' => 'anonymized+' . $user->id . '@mediconnect.local',
                'first_name' => 'Anonyme',
                'last_name' => 'Utilisateur',
                'phone' => null,
                'password' => Str::random(32),
            ]);

            UserConsent::where('user_id', $user->id)->delete();
        });

        Log::channel('security')->info('rgpd_admin_anonymize', [
            'admin_id' => auth()->id(),
            'user_id' => $user->id,
            'reason' => $request->input('reason'),
        ]);

        return redirect()->route('admin.rgpd.index')
            ->with('success', "Les données de l'utilisateur ont été anonymisées conformément au RGPD.");
    }
}
