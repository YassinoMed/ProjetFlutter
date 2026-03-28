<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('document_access_logs', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->uuid('actor_user_id')->nullable()->index();
            $table->string('action', 32)->index();
            $table->string('audience', 32)->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->json('context')->nullable();
            $table->timestamp('accessed_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
            $table->foreign('actor_user_id')->references('id')->on('users')->nullOnDelete();
        });

        Schema::create('document_processing_jobs', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->string('job_type', 64)->index();
            $table->string('queue_name', 64)->nullable()->index();
            $table->unsignedInteger('attempt')->default(1);
            $table->string('status', 32)->default('PENDING')->index();
            $table->timestamp('started_at_utc')->nullable()->index();
            $table->timestamp('completed_at_utc')->nullable()->index();
            $table->timestamp('failed_at_utc')->nullable()->index();
            $table->string('error_code', 64)->nullable();
            $table->string('error_message_sanitized', 255)->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
        });

        Schema::create('document_versions', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('document_id')->index();
            $table->unsignedInteger('version')->default(1);
            $table->uuid('created_by_user_id')->nullable()->index();
            $table->string('document_type', 64)->nullable()->index();
            $table->string('urgency_level', 32)->nullable()->index();
            $table->string('language_code', 12)->nullable();
            $table->string('source', 32)->nullable();
            $table->string('engine', 64)->nullable();
            $table->boolean('ocr_required')->default(false);
            $table->boolean('ocr_used')->default(false);
            $table->decimal('classification_confidence', 5, 2)->nullable();
            $table->json('structured_payload')->nullable();
            $table->json('missing_fields')->nullable();
            $table->json('warnings')->nullable();
            $table->timestamp('processed_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('documents')->cascadeOnDelete();
            $table->foreign('created_by_user_id')->references('id')->on('users')->nullOnDelete();
            $table->unique(['document_id', 'version']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('document_versions');
        Schema::dropIfExists('document_processing_jobs');
        Schema::dropIfExists('document_access_logs');
    }
};
