<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\LogsAdminActivity;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    use LogsAdminActivity;

    public function index()
    {
        $admin = auth('web')->user();
        return view('admin.profile.index', compact('admin'));
    }

    public function updateProfile(Request $request)
    {
        $admin = auth('web')->user();

        $validated = $request->validate([
            'first_name' => ['required', 'string', 'max:100'],
            'last_name'  => ['required', 'string', 'max:100'],
            'phone'      => ['nullable', 'string', 'max:20'],
        ]);

        $admin->update($validated);

        // Refactored: uses LogsAdminActivity trait
        $this->logAdminAction('admin_profile_updated');

        return redirect()->route('admin.profile.index')
            ->with('success', 'Profil mis à jour avec succès.');
    }

    public function updatePassword(Request $request)
    {
        $admin = auth('web')->user();

        $request->validate([
            'current_password' => ['required', 'current_password:web'],
            'password' => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()->symbols()],
        ], [
            'current_password.current_password' => 'Le mot de passe actuel est incorrect.',
            'password.confirmed' => 'Les mots de passe ne correspondent pas.',
        ]);

        $admin->update([
            'password' => Hash::make($request->input('password')),
        ]);

        // Refactored: uses LogsAdminActivity trait
        $this->logAdminAction('admin_password_changed');

        return redirect()->route('admin.profile.index')
            ->with('success', 'Mot de passe modifié avec succès.');
    }
}
