<?php

namespace App\Http\Controllers\Api;

use App\Enums\DocumentProcessingStatus;
use App\Enums\DocumentSummaryAudience;
use App\Enums\DocumentSummaryFormat;
use App\Enums\SecretaryPermission;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Documents\AskDocumentQuestionRequest;
use App\Http\Requests\Documents\ReanalyzeDocumentRequest;
use App\Http\Requests\Documents\UploadDocumentRequest;
use App\Http\Resources\DocumentEntityResource;
use App\Http\Resources\DocumentResource;
use App\Http\Resources\DocumentSummaryResource;
use App\Jobs\ProcessDocumentJob;
use App\Models\Document;
use App\Services\AuditService;
use App\Services\DelegationContextService;
use App\Services\Documents\Contracts\DocumentQuestionAnswerer;
use App\Services\Documents\DocumentAccessLogService;
use App\Services\Documents\DocumentStorageService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class DocumentController extends Controller
{
    public function __construct(
        private readonly DocumentStorageService $documentStorageService,
        private readonly AuditService $auditService,
        private readonly DelegationContextService $delegationContextService,
        private readonly DocumentAccessLogService $documentAccessLogService,
        private readonly DocumentQuestionAnswerer $documentQuestionAnswerer,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Document::class);

        $request->validate([
            'q' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', Rule::in(DocumentProcessingStatus::values())],
            'document_type' => ['nullable', 'string', 'max:64'],
            'patient_user_id' => ['nullable', 'uuid'],
            'doctor_user_id' => ['nullable', 'uuid'],
            'urgency_level' => ['nullable', 'string', 'max:32'],
            'from_date_utc' => ['nullable', 'date'],
            'to_date_utc' => ['nullable', 'date'],
            'updated_since_utc' => ['nullable', 'date'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $query = Document::query()
            ->with(['tags', 'latestExtraction'])
            ->when($request->filled('status'), fn (Builder $builder) => $builder->where('processing_status', (string) $request->string('status')))
            ->when($request->filled('document_type'), fn (Builder $builder) => $builder->where('document_type', (string) $request->string('document_type')))
            ->when($request->filled('patient_user_id'), fn (Builder $builder) => $builder->where('patient_user_id', (string) $request->string('patient_user_id')))
            ->when($request->filled('doctor_user_id'), fn (Builder $builder) => $builder->where('doctor_user_id', (string) $request->string('doctor_user_id')))
            ->when($request->filled('urgency_level'), fn (Builder $builder) => $builder->where('urgency_level', (string) $request->string('urgency_level')))
            ->when($request->filled('from_date_utc'), fn (Builder $builder) => $builder->where('created_at', '>=', Carbon::parse((string) $request->string('from_date_utc'), 'UTC')))
            ->when($request->filled('to_date_utc'), fn (Builder $builder) => $builder->where('created_at', '<=', Carbon::parse((string) $request->string('to_date_utc'), 'UTC')))
            ->when($request->filled('updated_since_utc'), fn (Builder $builder) => $builder->where('updated_at', '>', Carbon::parse((string) $request->string('updated_since_utc'), 'UTC')))
            ->when($request->filled('q'), function (Builder $builder) use ($request) {
                $term = (string) $request->string('q');

                $builder->where(function (Builder $nested) use ($term) {
                    $nested->where('title', 'like', '%'.$term.'%')
                        ->orWhere('document_type', 'like', '%'.$term.'%')
                        ->orWhereHas('tags', fn (Builder $tags) => $tags->where('tag', 'like', '%'.$term.'%'));
                });
            });

        $this->applyVisibilityScope($query, $request);

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
        $actingDoctorUserId = $this->resolveActingDoctorUserId($request);

        [$patientUserId, $doctorUserId] = match ($user->role) {
            UserRole::PATIENT => [$user->id, $payload['doctor_user_id'] ?? null],
            UserRole::DOCTOR => [$payload['patient_user_id'], $user->id],
            UserRole::SECRETARY => [$payload['patient_user_id'], $actingDoctorUserId],
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
                'uploaded_by_role' => $user->role?->value ?? $user->role,
                'acting_doctor_user_id' => $actingDoctorUserId,
            ],
            ...$stored,
        ]);

        ProcessDocumentJob::dispatch($document->id);

        $this->auditService->log($user, 'document.uploaded', $document, [
            'patient_user_id' => $patientUserId,
            'doctor_user_id' => $doctorUserId,
            'mime_type' => $document->mime_type,
        ], actingDoctorUserId: $actingDoctorUserId, request: $request);

        $this->documentAccessLogService->log(
            $document,
            $user,
            'UPLOAD',
            $request,
            $this->defaultAudienceForUser($request)->value,
        );

        return $this->respondSuccess([
            'document' => new DocumentResource($document->fresh()),
        ], 'Document uploaded successfully', 201);
    }

    public function show(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()
            ->with([
                'latestExtraction',
                'summaries' => fn (Builder $query) => $query->orderByDesc('version')->orderBy('audience')->orderBy('format'),
                'entities' => fn (Builder $query) => $query->orderByDesc('version')->orderBy('entity_type'),
                'tags',
            ])
            ->findOrFail($documentId);

        $this->authorize('view', $document);

        $this->documentAccessLogService->log(
            $document,
            $request->user(),
            'VIEW',
            $request,
            $this->defaultAudienceForUser($request)->value,
        );

        return $this->respondSuccess([
            'document' => new DocumentResource($document),
        ], 'Document retrieved successfully');
    }

    public function summary(string $documentId, Request $request): JsonResponse
    {
        $request->validate([
            'audience' => ['nullable', Rule::enum(DocumentSummaryAudience::class)],
            'format' => ['nullable', Rule::enum(DocumentSummaryFormat::class)],
        ]);

        $document = Document::query()->with('summaries')->findOrFail($documentId);
        $this->authorize('view', $document);

        $summaryQuery = $document->summaries()->orderByDesc('version')->orderBy('audience')->orderBy('format');

        if ($request->filled('audience')) {
            $summaryQuery->where('audience', (string) $request->string('audience'));
        }

        if ($request->filled('format')) {
            $summaryQuery->where('format', (string) $request->string('format'));
        }

        $this->documentAccessLogService->log(
            $document,
            $request->user(),
            'SUMMARY',
            $request,
            $request->input('audience') ?: $this->defaultAudienceForUser($request)->value,
            [
                'format' => $request->input('format'),
            ],
        );

        return $this->respondSuccess([
            'summaries' => DocumentSummaryResource::collection($summaryQuery->get()),
        ], 'Document summaries retrieved successfully');
    }

    public function entities(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()->with('entities')->findOrFail($documentId);
        $this->authorize('view', $document);

        $this->documentAccessLogService->log(
            $document,
            $request->user(),
            'ENTITIES',
            $request,
            $this->defaultAudienceForUser($request)->value,
        );

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

        $payload = $request->validated();

        $document->forceFill([
            'processing_status' => DocumentProcessingStatus::PENDING->value,
            'extraction_status' => DocumentProcessingStatus::PENDING->value,
            'summary_status' => DocumentProcessingStatus::PENDING->value,
            'last_error_code' => null,
            'last_error_message_sanitized' => null,
            'failed_at_utc' => null,
            'ocr_required' => (bool) ($payload['force_ocr'] ?? false) ?: $document->ocr_required,
            'source_metadata' => array_merge($document->source_metadata ?? [], [
                'reanalyze_request' => [
                    'reason' => $payload['reason'] ?? null,
                    'force_ocr' => (bool) ($payload['force_ocr'] ?? false),
                    'requested_at_utc' => now('UTC')->toISOString(),
                ],
            ]),
        ])->save();

        ProcessDocumentJob::dispatch($document->id);

        $this->auditService->log(
            $request->user(),
            'document.reanalyze.requested',
            $document,
            [
                'reason' => $payload['reason'] ?? null,
                'force_ocr' => (bool) ($payload['force_ocr'] ?? false),
            ],
            actingDoctorUserId: $this->resolveActingDoctorUserId($request),
            request: $request,
        );

        $this->documentAccessLogService->log(
            $document,
            $request->user(),
            'REANALYZE',
            $request,
            $this->defaultAudienceForUser($request)->value,
            [
                'reason' => $payload['reason'] ?? null,
                'force_ocr' => (bool) ($payload['force_ocr'] ?? false),
            ],
        );

        return $this->respondSuccess([
            'document' => new DocumentResource($document->fresh()),
        ], 'Document reanalysis queued successfully');
    }

    public function ask(string $documentId, AskDocumentQuestionRequest $request): JsonResponse
    {
        $document = Document::query()
            ->with(['latestExtraction', 'summaries', 'entities'])
            ->findOrFail($documentId);

        $this->authorize('view', $document);

        $payload = $request->validated();
        $audience = isset($payload['audience'])
            ? DocumentSummaryAudience::from($payload['audience'])
            : $this->defaultAudienceForUser($request);

        $answer = $this->documentQuestionAnswerer->answer(
            $document,
            $payload['question'],
            $audience,
        );

        $this->auditService->log(
            $request->user(),
            'document.question.asked',
            $document,
            [
                'audience' => $audience->value,
                'question_length' => mb_strlen($payload['question']),
                'insufficient_evidence' => $answer->insufficientEvidence,
            ],
            actingDoctorUserId: $this->resolveActingDoctorUserId($request),
            request: $request,
        );

        $this->documentAccessLogService->log(
            $document,
            $request->user(),
            'ASK',
            $request,
            $audience->value,
            [
                'question' => $payload['question'],
                'insufficient_evidence' => $answer->insufficientEvidence,
            ],
        );

        return $this->respondSuccess([
            'answer' => $answer->toArray(),
        ], 'Document question answered successfully');
    }

    public function destroy(string $documentId, Request $request): JsonResponse
    {
        $document = Document::query()->findOrFail($documentId);
        $this->authorize('delete', $document);

        Storage::disk($document->storage_disk)->delete($document->storage_path);

        $this->documentAccessLogService->log(
            $document,
            $request->user(),
            'DELETE',
            $request,
            $this->defaultAudienceForUser($request)->value,
        );

        $this->auditService->log(
            $request->user(),
            'document.deleted',
            $document,
            actingDoctorUserId: $this->resolveActingDoctorUserId($request),
            request: $request,
        );

        $document->delete();

        return $this->respondSuccess(null, 'Document deleted successfully');
    }

    private function applyVisibilityScope(Builder $query, Request $request): void
    {
        $user = $request->user();

        if ($user->role === UserRole::ADMIN) {
            return;
        }

        if ($user->role === UserRole::DOCTOR) {
            $query->where('doctor_user_id', $user->id);

            return;
        }

        if ($user->role === UserRole::SECRETARY) {
            $delegation = $this->delegationContextService
                ->assertSecretaryPermission($request, SecretaryPermission::MANAGE_DOCUMENTS);

            $query->where('doctor_user_id', $delegation->doctor_user_id);

            return;
        }

        $query->where('patient_user_id', $user->id);
    }

    private function resolveActingDoctorUserId(Request $request): ?string
    {
        $user = $request->user();

        if ($user === null) {
            return null;
        }

        if ($user->role === UserRole::SECRETARY) {
            return $this->delegationContextService
                ->assertSecretaryPermission($request, SecretaryPermission::MANAGE_DOCUMENTS)
                ->doctor_user_id;
        }

        if ($user->role === UserRole::DOCTOR) {
            return $user->id;
        }

        return null;
    }

    private function defaultAudienceForUser(Request $request): DocumentSummaryAudience
    {
        return match ($request->user()?->role) {
            UserRole::PATIENT => DocumentSummaryAudience::PATIENT,
            UserRole::SECRETARY, UserRole::ADMIN => DocumentSummaryAudience::ADMINISTRATIVE,
            default => DocumentSummaryAudience::PROFESSIONAL,
        };
    }
}
