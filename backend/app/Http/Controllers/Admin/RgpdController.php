<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\LogsAdminActivity;
use App\Http\Controllers\Admin\Concerns\SearchesUsers;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserConsent;
use App\Services\UserAnonymizationService;
use Illuminate\Http\Request;

class RgpdController extends Controller
{
    use LogsAdminActivity;
    use SearchesUsers;

    public function __construct(
        private readonly UserAnonymizationService $anonymization,
    ) {}

    public function index(Request $request)
    {
        $query = UserConsent::with('user');

        if ($request->filled('consent_type')) {
            $query->where('consent_type', $request->input('consent_type'));
        }

        // Refactored: use shared trait instead of duplicated search
        if ($request->filled('search')) {
            $this->applyRelatedUserSearch($query, 'user', $request->input('search'));
        }

        $consents = $query->orderByDesc('updated_at')->paginate(15);

        $stats = [
            'total_consents' => UserConsent::where('consented', true)->count(),
            'total_revoked' => UserConsent::where('consented', false)->count(),
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

        // Refactored: uses shared UserAnonymizationService (was duplicated in Api\RgpdController)
        $this->anonymization->anonymize(
            user: $user,
            actorId: auth('web')->id(),
            reason: $request->input('reason'),
        );

        return redirect()->route('admin.rgpd.index')
            ->with('success', "Les données de l'utilisateur ont été anonymisées conformément au RGPD.");
    }
}
