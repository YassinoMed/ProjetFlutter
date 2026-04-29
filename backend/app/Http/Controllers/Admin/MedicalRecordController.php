<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Admin\Concerns\SearchesUsers;
use App\Http\Controllers\Controller;
use App\Models\MedicalRecordMetadata;
use Illuminate\Http\Request;

class MedicalRecordController extends Controller
{
    use SearchesUsers;

    public function index(Request $request)
    {
        $query = MedicalRecordMetadata::with(['patient', 'doctor'])
            ->orderByDesc('recorded_at_utc');

        // Refactored: use shared trait for user search via relation
        if ($request->filled('search')) {
            $this->applyRelatedUserSearch($query, 'patient', $request->input('search'));
        }

        if ($request->filled('category')) {
            $query->where('category', $request->input('category'));
        }

        $records = $query->paginate(20);

        $stats = [
            'total' => MedicalRecordMetadata::count(),
            'active' => MedicalRecordMetadata::active()->count(),
            'expired' => MedicalRecordMetadata::whereNotNull('expires_at')
                ->where('expires_at', '<=', now())->count(),
            'categories' => MedicalRecordMetadata::distinct('category')->pluck('category')->filter()->values(),
        ];

        return view('admin.medical-records.index', compact('records', 'stats'));
    }
}
