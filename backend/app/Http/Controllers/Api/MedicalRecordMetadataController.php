<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\MedicalRecords\StoreMedicalRecordMetadataRequest;
use App\Http\Resources\MedicalRecordMetadataResource;
use App\Models\MedicalRecordMetadata;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class MedicalRecordMetadataController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $perPage = min(max((int) $request->query('per_page', 20), 1), 50);

        $query = MedicalRecordMetadata::query()
            ->when($request->filled('category'), fn ($q) => $q->where('category', $request->string('category')))
            ->when($request->filled('from_utc'), fn ($q) => $q->where('recorded_at_utc', '>=', Carbon::parse($request->string('from_utc'), 'UTC')))
            ->when($request->filled('to_utc'), fn ($q) => $q->where('recorded_at_utc', '<=', Carbon::parse($request->string('to_utc'), 'UTC')));

        if ($user->role === UserRole::ADMIN) {
            $query
                ->when($request->filled('patient_user_id'), fn ($q) => $q->where('patient_user_id', $request->string('patient_user_id')))
                ->when($request->filled('doctor_user_id'), fn ($q) => $q->where('doctor_user_id', $request->string('doctor_user_id')));
        } elseif ($user->role === UserRole::DOCTOR) {
            $query->where('doctor_user_id', $user->id)
                ->when($request->filled('patient_user_id'), fn ($q) => $q->where('patient_user_id', $request->string('patient_user_id')));
        } else {
            $query->where('patient_user_id', $user->id);
        }

        $records = $query
            ->orderByDesc('recorded_at_utc')
            ->cursorPaginate($perPage);

        return response()->json([
            'data' => MedicalRecordMetadataResource::collection(collect($records->items())),
            'next_cursor' => $records->nextCursor()?->encode(),
        ]);
    }

    public function show(string $recordId, Request $request): JsonResponse
    {
        $record = MedicalRecordMetadata::query()->findOrFail($recordId);

        $this->assertCanView($request->user(), $record);

        return response()->json([
            'record' => new MedicalRecordMetadataResource($record),
        ]);
    }

    public function store(StoreMedicalRecordMetadataRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();

        if ($user->role === UserRole::PATIENT) {
            $patientUserId = $user->id;
            $doctorUserId = null;
        } elseif ($user->role === UserRole::DOCTOR) {
            $patientUserId = $data['patient_user_id'];
            $doctorUserId = $user->id;
        } else {
            $patientUserId = $data['patient_user_id'];
            $doctorUserId = $data['doctor_user_id'] ?? null;
        }

        $record = MedicalRecordMetadata::query()->create([
            'patient_user_id' => $patientUserId,
            'doctor_user_id' => $doctorUserId,
            'category' => $data['category'],
            'metadata_encrypted' => $data['metadata_encrypted'],
            'recorded_at_utc' => Carbon::parse($data['recorded_at_utc'], 'UTC'),
        ]);

        return response()->json([
            'record' => new MedicalRecordMetadataResource($record),
        ], 201);
    }

    private function assertCanView($user, MedicalRecordMetadata $record): void
    {
        if ($user->role === UserRole::ADMIN) {
            return;
        }

        if ($record->patient_user_id === $user->id || $record->doctor_user_id === $user->id) {
            return;
        }

        throw new AccessDeniedHttpException;
    }
}
