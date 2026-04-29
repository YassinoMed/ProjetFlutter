<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Admin\Concerns\LogsAdminActivity;
use App\Http\Controllers\Admin\Concerns\SearchesUsers;
use App\Http\Controllers\Controller;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    use LogsAdminActivity;
    use SearchesUsers;

    public function index(Request $request)
    {
        $query = User::query();

        if ($request->filled('role')) {
            $query->where('role', $request->input('role'));
        }

        // Refactored: use shared trait instead of duplicated search logic
        if ($request->filled('search')) {
            $this->applyUserSearch($query, $request->input('search'));
        }

        $users = $query->orderByDesc('created_at')->paginate(15);

        return view('admin.users.index', compact('users'));
    }

    public function show(string $userId)
    {
        $user = User::findOrFail($userId);

        $extra = [];
        if ($user->role === UserRole::DOCTOR) {
            $extra['doctor'] = Doctor::where('user_id', $userId)->first();
        } elseif ($user->role === UserRole::PATIENT) {
            $extra['patient'] = Patient::where('user_id', $userId)->first();
        }

        return view('admin.users.show', compact('user', 'extra'));
    }

    public function toggleStatus(Request $request, string $userId)
    {
        $user = User::findOrFail($userId);

        $user->update([
            'is_active' => ! $user->is_active,
        ]);

        $status = $user->is_active ? 'activé' : 'désactivé';

        // Refactored: now logs the action (was missing before – P2 #8)
        $this->logAdminAction('user_status_toggled', [
            'target_user_id' => $userId,
            'new_status' => $status,
        ]);

        return redirect()->route('admin.users.index')
            ->with('success', "L'utilisateur {$user->first_name} {$user->last_name} a été {$status}.");
    }
}
