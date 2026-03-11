<?php

namespace Tests\Feature;

use App\Enums\DocumentSummaryAudience;
use App\Enums\DocumentSummaryFormat;
use App\Enums\DocumentType;
use App\Enums\DocumentUrgency;
use App\Jobs\ProcessDocumentJob;
use App\Models\Document;
use App\Models\User;
use App\Services\Documents\Contracts\DocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use App\Services\Documents\Data\DocumentAnalysisResult;
use App\Services\Documents\Data\TextExtractionResult;
use App\Services\Documents\DocumentAnalysisPipeline;
use Illuminate\Http\UploadedFile;
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
}
