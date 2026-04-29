<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ActivityLogController extends Controller
{
    public function index(Request $request)
    {
        $query = DB::table('activity_log')
            ->orderByDesc('created_at');

        // Filter by log_name (channel)
        if ($request->filled('log_name')) {
            $query->where('log_name', $request->input('log_name'));
        }

        // Filter by event
        if ($request->filled('event')) {
            $query->where('event', $request->input('event'));
        }

        // Search by description or properties
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('description', 'LIKE', "%{$search}%")
                    ->orWhere('properties', 'LIKE', "%{$search}%");
            });
        }

        // Date filter
        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->input('from'));
        }
        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->input('to'));
        }

        $logs = $query->paginate(25);

        // Get unique log names and events for filters
        $logNames = DB::table('activity_log')->distinct()->pluck('log_name')->filter()->values();
        $events = DB::table('activity_log')->distinct()->pluck('event')->filter()->values();

        return view('admin.activity-log.index', compact('logs', 'logNames', 'events'));
    }
}
