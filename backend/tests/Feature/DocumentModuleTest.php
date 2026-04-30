<?php

namespace Tests\Feature;

use App\Enums\DocumentProcessingStatus;
use App\Enums\DocumentSummaryAudience;
use App\Enums\DocumentSummaryFormat;
use App\Enums\DocumentType;
use App\Enums\DocumentUrgency;
use App\Jobs\ProcessDocumentJob;
use App\Models\Document;
use App\Models\DocumentAccessLog;
use App\Models\DocumentExtraction;
use App\Models\DocumentProcessingJob;
use App\Models\User;
use App\Services\Documents\Ai\HttpDocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use App\Services\Documents\Data\DocumentAnalysisResult;
use App\Services\Documents\Data\TextExtractionResult;
use App\Services\Documents\DocumentAnalysisPipeline;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\UsesTenantMigrations;
use Tests\TestCase;

class DocumentModuleTest extends TestCase
{
    use UsesTenantMigrations;

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('app.key', 'base64:'.base64_encode(random_bytes(32)));
        $this->bootTenantSchema();

        config()->set('documents.disk', 'documents-tests');
        Storage::fake('documents-tests');
    }

    public function test_doctor_can_upload_document_and_job_is_queued(): void
    {
        Queue::fake();

        $doctor = User::factory()->create(['role' => 'DOCTOR']);
        $patient = User::factory()->create(['role' => 'PATIENT']);

        Sanctum::actingAs($doctor);

        $response = $this->postJson('/api/documents/upload', [
            'title' => 'Bilan biologique mars',
            'patient_user_id' => $patient->id,
            'file' => UploadedFile::fake()->create('analyse.pdf', 256, 'application/pdf'),
        ]);

        $response->assertCreated();
        $response->assertJsonPath('data.document.title', 'Bilan biologique mars');
        $response->assertJsonPath('data.document.processing_status', 'PENDING');

        $document = Document::query()->firstOrFail();

        $this->assertSame($patient->id, $document->patient_user_id);
        $this->assertSame($doctor->id, $document->doctor_user_id);

        Queue::assertPushed(ProcessDocumentJob::class, 1);
    }

    public function test_upload_keyword_is_not_treated_as_document_id(): void
    {
        $patient = User::factory()->create(['role' => 'PATIENT']);

        Sanctum::actingAs($patient);

        $this->getJson('/api/documents/upload')
            ->assertStatus(405)
            ->assertJsonMissing([
                'message' => 'No query results for model [App\\Models\\Document] upload',
            ]);
    }

    public function test_upload_stores_mobile_mlkit_ocr_as_encrypted_extraction_seed(): void
    {
        Queue::fake();

        $patient = User::factory()->create(['role' => 'PATIENT']);

        Sanctum::actingAs($patient);

        $response = $this->postJson('/api/documents/upload', [
            'title' => 'Ordonnance ML Kit',
            'file' => UploadedFile::fake()->image('ordonnance.jpg'),
            'client_ocr_text' => "Ordonnance\nDate: 10/03/2026\nTraitement: Paracétamol 500 mg",
            'client_ocr_engine' => 'flutter_mlkit_text_recognition',
            'client_ocr_language' => 'fr',
            'client_ocr_confidence' => 0.82,
            'client_image_quality_score' => 0.76,
            'client_image_width' => 1280,
            'client_image_height' => 960,
            'client_image_quality_warnings' => json_encode(['Contraste faible']),
        ]);

        $response->assertCreated();
        $response->assertJsonPath('data.document.source_metadata.client_ocr.provided', true);
        $response->assertJsonPath('data.document.source_metadata.client_ocr.raw_text_stored_in_metadata', false);
        $response->assertJsonPath('data.document.source_metadata.client_image_quality.provided', true);
        $response->assertJsonPath('data.document.source_metadata.client_image_quality.contains_medical_content', false);

        $documentId = $response->json('data.document.id');
        $extraction = DocumentExtraction::query()
            ->where('document_id', $documentId)
            ->where('source', 'client_ocr')
            ->firstOrFail();

        $this->assertSame(0, $extraction->version);
        $this->assertSame('COMPLETED', $extraction->status->value);
        $this->assertStringContainsString('Paracétamol', $extraction->raw_text_encrypted);

        Queue::assertPushed(ProcessDocumentJob::class, 1);
    }

    public function test_pipeline_processes_document_with_bound_extractor_and_analyzer(): void
    {
        $patient = User::factory()->create(['role' => 'PATIENT']);

        Storage::disk('documents-tests')->put('medical-documents/'.$patient->id.'/analysis.txt', 'dummy');

        $document = Document::query()->create([
            'patient_user_id' => $patient->id,
            'uploaded_by_user_id' => $patient->id,
            'title' => 'Analyse glycémie',
            'original_filename' => 'analysis.txt',
            'mime_type' => 'text/plain',
            'file_extension' => 'txt',
            'file_size_bytes' => 5,
            'storage_disk' => 'documents-tests',
            'storage_path' => 'medical-documents/'.$patient->id.'/analysis.txt',
            'sha256_checksum' => hash('sha256', 'dummy'),
        ]);

        app()->bind(DocumentTextExtractor::class, fn () => new class implements DocumentTextExtractor
        {
            public function extract(Document $document): TextExtractionResult
            {
                return new TextExtractionResult(
                    rawText: "Patient: Alice Martin\nDate: 2026-03-10\nDiagnostic: Diabète de type 2\nTraitement: Metformine 500 mg matin et soir",
                    normalizedText: 'Patient: Alice Martin Date: 2026-03-10 Diagnostic: Diabète de type 2 Traitement: Metformine 500 mg matin et soir',
                    source: 'plain_text',
                    engine: 'fake',
                    languageCode: 'fr',
                    confidenceScore: 1.0,
                );
            }
        });

        app()->bind(DocumentAiAnalyzer::class, fn () => new class implements DocumentAiAnalyzer
        {
            public function analyze(Document $document, TextExtractionResult $extraction): DocumentAnalysisResult
            {
                return new DocumentAnalysisResult(
                    documentType: DocumentType::LAB_RESULT,
                    urgency: DocumentUrgency::MEDIUM,
                    classificationConfidence: 0.91,
                    structuredFields: [
                        'patient_name' => 'Alice Martin',
                        'document_date' => '2026-03-10',
                        'diagnosis' => 'Diabète de type 2',
                        'treatments' => ['Metformine 500 mg matin et soir'],
                    ],
                    entities: [
                        [
                            'entity_type' => 'patient_name',
                            'label' => 'Nom du patient',
                            'value' => 'Alice Martin',
                            'confidence_score' => 0.99,
                            'is_sensitive' => true,
                            'qualifiers' => [],
                        ],
                    ],
                    summaries: [
                        [
                            'audience' => DocumentSummaryAudience::PATIENT->value,
                            'format' => DocumentSummaryFormat::SHORT->value,
                            'summary_text' => 'Le document mentionne un diabète de type 2 et un traitement par metformine.',
                            'structured_payload' => null,
                            'factual_basis' => ['Diagnostic: Diabète de type 2', 'Traitement: Metformine 500 mg matin et soir'],
                            'missing_fields' => [],
                            'confidence_score' => 0.95,
                        ],
                    ],
                    tags: [
                        ['tag' => 'DIABÈTE', 'confidence_score' => 0.88],
                    ],
                    warnings: [],
                    missingInformation: [],
                    languageCode: 'fr',
                );
            }
        });

        $processed = app(DocumentAnalysisPipeline::class)->process($document);

        $this->assertSame('COMPLETED', $processed->processing_status->value);
        $this->assertSame('LAB_RESULT', $processed->document_type->value);
        $this->assertDatabaseHas('document_summaries', [
            'document_id' => $document->id,
            'audience' => 'PATIENT',
            'format' => 'SHORT',
        ]);
        $this->assertDatabaseHas('document_entities', [
            'document_id' => $document->id,
            'entity_type' => 'patient_name',
        ]);
        $this->assertDatabaseHas('document_tags', [
            'document_id' => $document->id,
            'tag' => 'DIABÈTE',
        ]);
    }

    public function test_patient_cannot_access_other_patient_document(): void
    {
        $owner = User::factory()->create(['role' => 'PATIENT']);
        $otherPatient = User::factory()->create(['role' => 'PATIENT']);

        Storage::disk('documents-tests')->put('medical-documents/'.$owner->id.'/private.txt', 'private');

        $document = Document::query()->create([
            'patient_user_id' => $owner->id,
            'uploaded_by_user_id' => $owner->id,
            'title' => 'Document privé',
            'original_filename' => 'private.txt',
            'mime_type' => 'text/plain',
            'file_extension' => 'txt',
            'file_size_bytes' => 7,
            'storage_disk' => 'documents-tests',
            'storage_path' => 'medical-documents/'.$owner->id.'/private.txt',
            'sha256_checksum' => hash('sha256', 'private'),
        ]);

        Sanctum::actingAs($otherPatient);

        $this->getJson("/api/documents/{$document->id}")
            ->assertForbidden();
    }

    public function test_document_detail_and_processing_endpoint_expose_pipeline_and_jobs(): void
    {
        $patient = User::factory()->create(['role' => 'PATIENT']);

        Storage::disk('documents-tests')->put('medical-documents/'.$patient->id.'/processing.txt', 'processing');

        $document = Document::query()->create([
            'patient_user_id' => $patient->id,
            'uploaded_by_user_id' => $patient->id,
            'title' => 'Compte rendu en analyse',
            'original_filename' => 'processing.txt',
            'mime_type' => 'text/plain',
            'file_extension' => 'txt',
            'file_size_bytes' => 10,
            'storage_disk' => 'documents-tests',
            'storage_path' => 'medical-documents/'.$patient->id.'/processing.txt',
            'sha256_checksum' => hash('sha256', 'processing'),
            'processing_status' => DocumentProcessingStatus::PROCESSING->value,
            'extraction_status' => DocumentProcessingStatus::COMPLETED->value,
            'summary_status' => DocumentProcessingStatus::PROCESSING->value,
            'ocr_required' => true,
            'ocr_used' => true,
        ]);

        DocumentProcessingJob::query()->create([
            'document_id' => $document->id,
            'job_type' => ProcessDocumentJob::class,
            'queue_name' => 'documents',
            'attempt' => 1,
            'status' => DocumentProcessingStatus::PROCESSING->value,
            'started_at_utc' => now('UTC')->subMinute(),
        ]);

        Sanctum::actingAs($patient);

        $this->getJson("/api/documents/{$document->id}")
            ->assertOk()
            ->assertJsonPath('data.document.processing_pipeline.overall_status', 'PROCESSING')
            ->assertJsonPath('data.document.processing_pipeline.ocr_used', true)
            ->assertJsonPath('data.document.processing_jobs.0.job_label', 'Analyse du document')
            ->assertJsonPath('data.document.processing_jobs.0.status', 'PROCESSING');

        $this->getJson("/api/documents/{$document->id}/processing")
            ->assertOk()
            ->assertJsonPath('data.processing_jobs.0.job_label', 'Analyse du document')
            ->assertJsonPath('data.processing_jobs.0.status', 'PROCESSING');
    }

    public function test_medical_api_provider_analyzes_document_via_generate_endpoint(): void
    {
        config()->set('documents.ai.provider', 'medical_api');
        config()->set('documents.ai.base_url', 'https://medical-ai.test/proxy/8097');
        config()->set('documents.ai.generate_path', '/generate');
        config()->set('documents.ai.max_new_tokens', 512);
        config()->set('documents.ai.temperature', 0.0);

        Http::fake([
            'https://medical-ai.test/proxy/8097/generate' => Http::response([
                'response' => json_encode([
                    'document_type' => 'LAB_RESULT',
                    'document_date' => '2026-04-01',
                    'patient_name' => 'Alice Martin',
                    'important_lab_results' => [
                        ['label' => 'HbA1c', 'value' => '7.2', 'unit' => '%', 'certainty' => 'HIGH'],
                    ],
                    'treatments' => ['Metformine 500 mg'],
                    'recommendations' => ['Contrôle médical recommandé'],
                    'urgency_level' => 'MEDIUM',
                    'facts_only' => ['HbA1c: 7.2 %.', 'Traitement: Metformine 500 mg.'],
                    'missing_fields' => [],
                    'uncertainty_notes' => [],
                    'keywords' => ['diabete'],
                    'confidence' => 0.92,
                ]),
            ], 200),
        ]);

        $patient = User::factory()->create(['role' => 'PATIENT']);
        $document = Document::query()->create([
            'patient_user_id' => $patient->id,
            'uploaded_by_user_id' => $patient->id,
            'title' => 'Bilan HbA1c',
            'original_filename' => 'hba1c.txt',
            'mime_type' => 'text/plain',
            'file_extension' => 'txt',
            'file_size_bytes' => 10,
            'storage_disk' => 'documents-tests',
            'storage_path' => 'medical-documents/'.$patient->id.'/hba1c.txt',
            'sha256_checksum' => hash('sha256', 'hba1c'),
        ]);

        $result = app(HttpDocumentAiAnalyzer::class)->analyze(
            $document,
            new TextExtractionResult(
                rawText: 'HbA1c 7.2 %. Traitement: Metformine 500 mg.',
                normalizedText: 'HbA1c 7.2 %. Traitement: Metformine 500 mg.',
                source: 'plain_text',
                engine: 'fake',
                languageCode: 'fr',
                confidenceScore: 1.0,
            ),
        );

        $this->assertSame(DocumentType::LAB_RESULT, $result->documentType);
        $this->assertSame(DocumentUrgency::MEDIUM, $result->urgency);
        $this->assertSame('Alice Martin', $result->structuredFields['patient_name']);
        $this->assertNotEmpty($result->summaries);

        Http::assertSent(fn ($request) => $request->url() === 'https://medical-ai.test/proxy/8097/generate'
            && $request['temperature'] === 0.0
            && str_contains($request['prompt'], 'Texte OCR/extrait'));
    }

    public function test_medical_api_document_chat_uses_chat_endpoint_without_logging_plain_question(): void
    {
        config()->set('documents.document_chat_driver', 'http');
        config()->set('documents.ai.provider', 'medical_api');
        config()->set('documents.ai.base_url', 'https://medical-ai.test/proxy/8097');
        config()->set('documents.ai.chat_path', '/chat');

        Http::fake([
            'https://medical-ai.test/proxy/8097/chat' => Http::response([
                'response' => json_encode([
                    'answer' => 'Le document mentionne une HbA1c à 7.2 %.',
                    'insufficient_evidence' => false,
                    'evidence' => [
                        [
                            'source' => 'document_text',
                            'field' => 'important_lab_results',
                            'excerpt' => 'HbA1c 7.2 %',
                            'certainty' => 'HIGH',
                        ],
                    ],
                    'uncertainty_notes' => [],
                    'confidence_score' => 0.91,
                ]),
            ], 200),
        ]);

        $patient = User::factory()->create(['role' => 'PATIENT']);
        $document = Document::query()->create([
            'patient_user_id' => $patient->id,
            'uploaded_by_user_id' => $patient->id,
            'title' => 'Bilan HbA1c',
            'original_filename' => 'hba1c.txt',
            'mime_type' => 'text/plain',
            'file_extension' => 'txt',
            'file_size_bytes' => 10,
            'storage_disk' => 'documents-tests',
            'storage_path' => 'medical-documents/'.$patient->id.'/hba1c.txt',
            'sha256_checksum' => hash('sha256', 'hba1c'),
        ]);

        DocumentExtraction::query()->create([
            'document_id' => $document->id,
            'version' => 1,
            'status' => DocumentProcessingStatus::COMPLETED->value,
            'source' => 'plain_text',
            'engine' => 'fake',
            'language_code' => 'fr',
            'raw_text_encrypted' => 'HbA1c 7.2 %',
            'normalized_text_encrypted' => 'HbA1c 7.2 %',
            'structured_payload' => [
                'important_lab_results' => ['HbA1c 7.2 %'],
            ],
            'confidence_score' => 1.0,
            'started_at_utc' => now('UTC'),
            'completed_at_utc' => now('UTC'),
        ]);

        Sanctum::actingAs($patient);

        $question = 'Quelle est la valeur HbA1c dans ce document ?';

        $this->postJson("/api/documents/{$document->id}/ask", [
            'question' => $question,
            'audience' => DocumentSummaryAudience::PATIENT->value,
        ])
            ->assertOk()
            ->assertJsonPath('data.answer.answer', 'Le document mentionne une HbA1c à 7.2 %.')
            ->assertJsonPath('data.answer.insufficient_evidence', false);

        $this->assertDatabaseHas('document_access_logs', [
            'document_id' => $document->id,
            'action' => 'ASK',
        ]);

        $accessLog = DocumentAccessLog::query()
            ->where('document_id', $document->id)
            ->where('action', 'ASK')
            ->latest('id')
            ->firstOrFail();

        $this->assertArrayNotHasKey('question', $accessLog->context);
        $this->assertSame(hash('sha256', $question), $accessLog->context['question_hash']);

        Http::assertSent(fn ($request) => $request->url() === 'https://medical-ai.test/proxy/8097/chat'
            && $request['messages'][1]['content'] !== ''
            && str_contains($request['messages'][1]['content'], 'Question utilisateur'));
    }
}
