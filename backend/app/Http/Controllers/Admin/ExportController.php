<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExportController extends Controller
{
    /**
     * Export users as CSV.
     */
    public function users(Request $request): StreamedResponse
    {
        Log::channel('security')->info('admin_export_users', [
            'admin_id' => auth('web')->id(),
            'ip' => $request->ip(),
        ]);

        $users = User::orderBy('created_at', 'desc')->get();

        return $this->streamCsv(
            "users_export_" . now()->format('Y-m-d_His') . ".csv",
            ['ID', 'Prénom', 'Nom', 'Email', 'Rôle', 'Téléphone', 'Inscrit le'],
            $users->map(function ($user) {
                return [
                    $user->id,
                    $user->first_name,
                    $user->last_name,
                    $user->email,
                    $user->role?->value ?? $user->role,
                    $user->phone ?? '',
                    $user->created_at?->format('d/m/Y H:i') ?? '',
                ];
            })->toArray()
        );
    }

    /**
     * Export appointments as CSV.
     */
    public function appointments(Request $request): StreamedResponse
    {
        Log::channel('security')->info('admin_export_appointments', [
            'admin_id' => auth('web')->id(),
            'ip' => $request->ip(),
        ]);

        $appointments = Appointment::with(['patient', 'doctor'])
            ->orderByDesc('starts_at_utc')
            ->get();

        return $this->streamCsv(
            "appointments_export_" . now()->format('Y-m-d_His') . ".csv",
            ['ID', 'Patient', 'Médecin', 'Date Début', 'Date Fin', 'Statut', 'Créé le'],
            $appointments->map(function ($a) {
                return [
                    $a->id,
                    ($a->patient?->first_name ?? '') . ' ' . ($a->patient?->last_name ?? ''),
                    'Dr. ' . ($a->doctor?->first_name ?? '') . ' ' . ($a->doctor?->last_name ?? ''),
                    $a->starts_at_utc?->format('d/m/Y H:i') ?? '',
                    $a->ends_at_utc?->format('d/m/Y H:i') ?? '',
                    $a->status?->value ?? $a->status,
                    $a->created_at?->format('d/m/Y H:i') ?? '',
                ];
            })->toArray()
        );
    }

    /**
     * Stream a CSV file to the browser.
     */
    private function streamCsv(string $filename, array $headers, array $rows): StreamedResponse
    {
        return response()->streamDownload(function () use ($headers, $rows) {
            $handle = fopen('php://output', 'w');

            // UTF-8 BOM for Excel compatibility
            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));

            fputcsv($handle, $headers, ';');

            foreach ($rows as $row) {
                fputcsv($handle, $row, ';');
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }
}
