<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('documents', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('patient_user_id')->nullable()->index();
            $table->uuid('doctor_user_id')->nullable()->index();
            $table->uuid('uploaded_by_user_id')->index();
            $table->string('title', 160);
            $table->string('original_filename', 255);
            $table->string('mime_type', 120)->index();
            $table->string('file_extension', 16)->nullable()->index();
            $table->unsignedBigInteger('file_size_bytes');
            $table->string('storage_disk', 64);
            $table->string('storage_path', 255)->unique();
            $table->string('sha256_checksum', 64)->index();
            $table->string('document_type', 64)->nullable()->index();
            $table->string('processing_status', 32)->default('PENDING')->index();
            $table->string('extraction_status', 32)->default('PENDING')->index();
            $table->string('summary_status', 32)->default('PENDING')->index();
            $table->boolean('ocr_required')->default(false);
            $table->boolean('ocr_used')->default(false);
            $table->string('urgency_level', 32)->nullable()->index();
            $table->string('language_code', 12)->nullable();
            $table->timestamp('document_date_utc')->nullable()->index();
            $table->timestamp('processed_at_utc')->nullable()->index();
            $table->timestamp('failed_at_utc')->nullable()->index();
            $table->decimal('classification_confidence', 5, 2)->nullable();
            $table->string('last_error_code', 64)->nullable();
            $table->string('last_error_message_sanitized', 255)->nullable();
            $table->json('source_metadata')->nullable();
            $table->timestamps();

            $table->foreign('patient_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('doctor_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('uploaded_by_user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('document_extractions', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->unsignedInteger('version')->default(1);
            $table->string('status', 32)->default('PENDING')->index();
            $table->string('source', 32)->nullable();
            $table->string('engine', 64)->nullable();
            $table->string('language_code', 12)->nullable();
            $table->longText('raw_text_encrypted')->nullable();
            $table->longText('normalized_text_encrypted')->nullable();
            $table->json('structured_payload')->nullable();
            $table->json('missing_sections')->nullable();
            $table->decimal('confidence_score', 5, 2)->nullable();
            $table->timestamp('started_at_utc')->nullable()->index();
            $table->timestamp('completed_at_utc')->nullable()->index();
            $table->timestamp('failed_at_utc')->nullable()->index();
            $table->string('error_code', 64)->nullable();
            $table->string('error_message_sanitized', 255)->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
            $table->unique(['document_id', 'version']);
        });

        Schema::create('document_summaries', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->unsignedInteger('version')->default(1);
            $table->string('status', 32)->default('PENDING')->index();
            $table->string('audience', 32)->index();
            $table->string('format', 32)->index();
            $table->longText('summary_text_encrypted')->nullable();
            $table->json('structured_payload')->nullable();
            $table->json('factual_basis')->nullable();
            $table->json('missing_fields')->nullable();
            $table->decimal('confidence_score', 5, 2)->nullable();
            $table->timestamp('generated_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
            $table->unique(['document_id', 'version', 'audience', 'format']);
        });

        Schema::create('document_entities', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->unsignedInteger('version')->default(1);
            $table->string('entity_type', 64)->index();
            $table->string('label', 120);
            $table->text('value_encrypted');
            $table->boolean('is_sensitive')->default(true);
            $table->decimal('confidence_score', 5, 2)->nullable();
            $table->json('qualifiers')->nullable();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
            $table->index(['document_id', 'version']);
        });

        Schema::create('document_tags', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->string('tag', 64)->index();
            $table->decimal('confidence_score', 5, 2)->nullable();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
            $table->unique(['document_id', 'tag']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('document_tags');
        Schema::dropIfExists('document_entities');
        Schema::dropIfExists('document_summaries');
        Schema::dropIfExists('document_extractions');
        Schema::dropIfExists('documents');
    }
};
