<?php

namespace App\Http\Controllers\Api;

use App\Enums\DocumentProcessingStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Documents\ReanalyzeDocumentRequest;
use App\Http\Requests\Documents\UploadDocumentRequest;
use App\Http\Resources\DocumentEntityResource;
use App\Http\Resources\DocumentResource;
use App\Http\Resources\DocumentSummaryResource;
use App\Jobs\ProcessDocumentJob;
use App\Models\Document;
use App\Services\AuditService;
use App\Services\Documents\DocumentStorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;

class DocumentController extends Controller
{
    public function __construct(
        private readonly DocumentStorageService $documentStorageService,
        private readonly AuditService $auditService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Document::class);

        $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', 'string'],
            'document_type' => ['nullable', 'string', 'max:64'],
            'patient_user_id' => ['nullable', 'uuid'],
            'from_date_utc' => ['nullable', 'date'],
            'to_date_utc' => ['nullable', 'date'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $user = $request->user();
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $query = Document::query()
            ->with('tags')
            ->when($request->filled('status'), fn ($builder) => $builder->where('processing_status', $request->string('status')))
            ->when($request->filled('document_type'), fn ($builder) => $builder->where('document_type', $request->string('document_type')))
            ->when($request->filled('from_date_utc'), fn ($builder) => $builder->where('created_at', '>=', Carbon::parse($request->string('from_date_utc'), 'UTC')))
            ->when($request->filled('to_date_utc'), fn ($builder) => $builder->where('created_at', '<=', Carbon::parse($request->string('to_date_utc'), 'UTC')))
            ->when($request->filled('q'), function ($builder) use ($request) {
                $term = (string) $request->string('q');

                $builder->where(function ($nested) use ($term) {
                    $nested->where('title', 'like', '%'.$term.'%')
                        ->orWhere('document_type', 'like', '%'.$term.'%')
                        ->orWhereHas('tags', fn ($tags) => $tags->where('tag', 'like', '%'.$term.'%'));
                });
            });

        if ($user->role === UserRole::ADMIN) {
            $query->when($request->filled('patient_user_id'), fn ($builder) => $builder->where('patient_user_id', $request->string('patient_user_id')));
        } elseif ($user->role === UserRole::DOCTOR) {
            $query->where(function ($builder) use ($user) {
                $builder->where('doctor_user_id', $user->id)
                    ->orWhere('uploaded_by_user_id', $user->id);
            });
        } else {
            $query->where(function ($builder) use ($user) {
                $builder->where('patient_user_id', $user->id)
                    ->orWhere('uploaded_by_user_id', $user->id);
            });
        }

        $documents = $query->orderByDesc('created_at')->cursorPaginate($perPage);

        return $this->respondSuccess(
            DocumentResource::collection(collect($documents->items())),
            'Documents retrieved successfully',
            200,
            ['next_cursor' => $documents->nextCursor()?->encode()],
        );
    }

    public function upload(UploadDocumentRequest $request): JsonResponse
    {
        $this->authorize('create', Document::class);

        $user = $request->user();
        $payload = $request->validated();
        $stored = $this->documentStorageService->store($request->file('file'), $user);

        [$patientUserId, $doctorUserId] = match ($user->role) {
            UserRole::PATIENT => [$user->id, $payload['doctor_user_id'] ?? null],
            UserRole::DOCTOR => [$payload['patient_user_id'], $user->id],
            default => [$payload['patient_user_id'] ?? null, $payload['doctor_user_id'] ?? null],
        };

        $document = Document::query()->create([
            'patient_user_id' => $patientUserId,
            'doctor_user_id' => $doctorUserId,
            'uploaded_by_user_id' => $user->id,
            'title' => $payload['title'],
            'document_type' => $payload['document_type_hint'] ?? null,
            'processing_status' => DocumentProcessingStatus::PENDING->value,
            'extraction_status' => DocumentProcessingStatus::PENDING->value,
            'summary_status' => DocumentProcessingStatus::PENDING->value,
            'document_date_utc' => isset($payload['document_date_utc']) ? Carbon::parse($payload['document_date_utc'], 'UTC') : null,
            'source_metadata' => [
                'uploaded_mime' => $stored['mime_type'],
                'uploaded_from' => 'api',
            ],
            ...$stored,
        ]);

        ProcessDocumentJob::dispatch($document->id);

        $this->auditService->log($user, 'document.uploaded', $document, [
            'patient_user_id' => $patientUserId,
            'doctor_user_id' => $doctorUserId,
            'mime_type' => $document->mime_type,
        ], request: $request);

        return $this->respondSuccess([
            'document' => new DocumentResource($document),
        ], 'Document uploaded successfully', 201);
    }

    public function show(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()
            ->with([
                'latestExtraction',
                'summaries' => fn ($query) => $query->orderBy('version')->orderBy('audience')->orderBy('format'),
                'entities' => fn ($query) => $query->orderBy('version')->orderBy('entity_type'),
                'tags',
            ])
            ->findOrFail($documentId);

        $this->authorize('view', $document);

        return $this->respondSuccess([
            'document' => new DocumentResource($document),
        ], 'Document retrieved successfully');
    }

    public function summary(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()->with('summaries')->findOrFail($documentId);
        $this->authorize('view', $document);

        return $this->respondSuccess([
            'summaries' => DocumentSummaryResource::collection(
                $document->summaries()->orderByDesc('version')->orderBy('audience')->orderBy('format')->get()
            ),
        ], 'Document summaries retrieved successfully');
    }

    public function entities(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()->with('entities')->findOrFail($documentId);
        $this->authorize('view', $document);

        return $this->respondSuccess([
            'entities' => DocumentEntityResource::collection(
                $document->entities()->orderByDesc('version')->orderBy('entity_type')->get()
            ),
        ], 'Document entities retrieved successfully');
    }

    public function reanalyze(string $documentId, ReanalyzeDocumentRequest $request): JsonResponse
    {
        $document = Document::query()->findOrFail($documentId);
        $this->authorize('reanalyze', $document);

        $document->forceFill([
            'processing_status' => DocumentProcessingStatus::PENDING->value,
            'extraction_status' => DocumentProcessingStatus::PENDING->value,
            'summary_status' => DocumentProcessingStatus::PENDING->value,
            'last_error_code' => null,
            'last_error_message_sanitized' => null,
            'failed_at_utc' => null,
        ])->save();

        ProcessDocumentJob::dispatch($document->id);

        $this->auditService->log(
            $request->user(),
            'document.reanalyze.requested',
            $document,
            request: $request,
        );

        return $this->respondSuccess([
            'document' => new DocumentResource($document),
        ], 'Document reanalysis queued successfully');
    }

    public function destroy(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()->findOrFail($documentId);
        $this->authorize('delete', $document);

        Storage::disk($document->storage_disk)->delete($document->storage_path);
        $this->auditService->log($request->user(), 'document.deleted', $document, request: $request);
        $document->delete();

        return $this->respondSuccess(null, 'Document deleted successfully');
    }
}
