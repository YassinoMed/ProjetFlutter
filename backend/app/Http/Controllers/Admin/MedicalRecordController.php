<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\MedicalRecordMetadata;
use Illuminate\Http\Request;

class MedicalRecordController extends Controller
{
    public function index(Request $request)
    {
        $query = MedicalRecordMetadata::with(['patient', 'doctor'])
            ->orderByDesc('recorded_at_utc');

        if ($request->filled('search')) {
            $search = e($request->input('search'));
            $query->whereHas('patient', function ($q) use ($search) {
                $q->where('first_name', 'LIKE', "%{$search}%")
                  ->orWhere('last_name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
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
