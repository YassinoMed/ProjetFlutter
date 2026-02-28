<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        // Filter by role
        if ($request->filled('role')) {
            $query->where('role', $request->input('role'));
        }

        // Search by name or email
        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'LIKE', "%{$search}%")
                  ->orWhere('last_name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(15);

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
            'is_active' => !$user->is_active,
        ]);

        $status = $user->is_active ? 'activé' : 'désactivé';

        return redirect()->route('admin.users.index')
            ->with('success', "L'utilisateur {$user->first_name} {$user->last_name} a été {$status}.");
    }
}
