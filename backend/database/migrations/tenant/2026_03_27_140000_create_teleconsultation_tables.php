<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teleconsultations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('appointment_id')->unique();
            $table->uuid('conversation_id')->nullable()->index();
            $table->uuid('current_call_session_id')->nullable()->index();
            $table->uuid('patient_user_id')->index();
            $table->uuid('doctor_user_id')->index();
            $table->uuid('created_by_user_id')->nullable()->index();
            $table->string('call_type', 16)->default('VIDEO')->index();
            $table->string('status', 32)->default('scheduled')->index();
            $table->string('session_reference', 64)->unique();
            $table->timestamp('scheduled_starts_at_utc')->index();
            $table->timestamp('scheduled_ends_at_utc')->index();
            $table->timestamp('ringing_started_at_utc')->nullable()->index();
            $table->timestamp('started_at_utc')->nullable()->index();
            $table->timestamp('ended_at_utc')->nullable()->index();
            $table->timestamp('expires_at_utc')->nullable()->index();
            $table->string('cancellation_reason', 500)->nullable();
            $table->string('failure_reason', 500)->nullable();
            $table->json('server_metadata')->nullable();
            $table->timestamps();

            $table->foreign('appointment_id')->references('id')->on('appointments')->cascadeOnDelete();
            $table->foreign('conversation_id')->references('id')->on('conversations')->nullOnDelete();
            $table->foreign('current_call_session_id')->references('id')->on('call_sessions')->nullOnDelete();
            $table->foreign('patient_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('doctor_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('created_by_user_id')->references('id')->on('users')->nullOnDelete();
            $table->index(['doctor_user_id', 'status', 'scheduled_starts_at_utc']);
            $table->index(['patient_user_id', 'status', 'scheduled_starts_at_utc']);
        });

        Schema::create('teleconsultation_participants', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('teleconsultation_id')->index();
            $table->uuid('user_id')->index();
            $table->string('role', 32)->index();
            $table->timestamp('invited_at_utc')->nullable()->index();
            $table->timestamp('joined_at_utc')->nullable()->index();
            $table->timestamp('left_at_utc')->nullable()->index();
            $table->timestamp('last_seen_at_utc')->nullable()->index();
            $table->boolean('can_publish_audio')->default(true);
            $table->boolean('can_publish_video')->default(true);
            $table->timestamp('access_revoked_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('teleconsultation_id')->references('id')->on('teleconsultations')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['teleconsultation_id', 'user_id']);
        });

        Schema::create('call_events', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('teleconsultation_id')->index();
            $table->uuid('call_session_id')->nullable()->index();
            $table->uuid('actor_user_id')->nullable()->index();
            $table->uuid('target_user_id')->nullable()->index();
            $table->string('event_name', 64)->index();
            $table->string('direction', 16)->nullable()->index();
            $table->json('payload')->nullable();
            $table->timestamp('occurred_at_utc')->index();
            $table->timestamps();

            $table->foreign('teleconsultation_id')->references('id')->on('teleconsultations')->cascadeOnDelete();
            $table->foreign('call_session_id')->references('id')->on('call_sessions')->nullOnDelete();
            $table->foreign('actor_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('target_user_id')->references('id')->on('users')->nullOnDelete();
            $table->index(['teleconsultation_id', 'occurred_at_utc']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('call_events');
        Schema::dropIfExists('teleconsultation_participants');
        Schema::dropIfExists('teleconsultations');
    }
};
