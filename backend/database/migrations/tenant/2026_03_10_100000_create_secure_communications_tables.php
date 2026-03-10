<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('consultation_id')->nullable()->unique();
            $table->uuid('initiated_by_user_id')->nullable()->index();
            $table->string('type', 32)->default('DIRECT_MEDICAL')->index();
            $table->timestamp('last_message_at_utc')->nullable()->index();
            $table->json('server_metadata')->nullable();
            $table->timestamps();

            $table->foreign('consultation_id')->references('id')->on('appointments')->nullOnDelete();
            $table->foreign('initiated_by_user_id')->references('id')->on('users')->nullOnDelete();
        });

        Schema::create('conversation_participants', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('conversation_id')->index();
            $table->uuid('user_id')->index();
            $table->string('role', 32)->index();
            $table->boolean('is_active')->default(true);
            $table->timestamp('joined_at_utc')->nullable()->index();
            $table->timestamp('last_seen_at_utc')->nullable()->index();
            $table->timestamp('last_delivered_at_utc')->nullable();
            $table->timestamp('last_read_at_utc')->nullable();
            $table->timestamps();

            $table->foreign('conversation_id')->references('id')->on('conversations')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['conversation_id', 'user_id']);
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('conversation_id')->index();
            $table->uuid('sender_user_id')->index();
            $table->string('client_message_id', 128)->nullable();
            $table->string('message_type', 32)->default('TEXT')->index();
            $table->text('ciphertext');
            $table->string('nonce', 255);
            $table->string('e2ee_version', 32)->default('1');
            $table->string('sender_key_id', 128)->nullable();
            $table->json('server_metadata')->nullable();
            $table->timestamp('sent_at_utc')->index();
            $table->timestamp('server_received_at_utc')->index();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamps();

            $table->foreign('conversation_id')->references('id')->on('conversations')->cascadeOnDelete();
            $table->foreign('sender_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['conversation_id', 'client_message_id']);
            $table->index(['conversation_id', 'sent_at_utc']);
        });

        Schema::create('message_receipts', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('message_id')->index();
            $table->uuid('user_id')->index();
            $table->string('status', 32)->index();
            $table->timestamp('status_at_utc')->index();
            $table->timestamps();

            $table->foreign('message_id')->references('id')->on('messages')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['message_id', 'user_id']);
        });

        Schema::create('call_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('consultation_id')->nullable()->index();
            $table->uuid('conversation_id')->nullable()->index();
            $table->uuid('initiated_by_user_id')->index();
            $table->uuid('ended_by_user_id')->nullable()->index();
            $table->string('call_type', 16)->default('VIDEO')->index();
            $table->string('current_state', 32)->default('INITIATED')->index();
            $table->timestamp('started_ringing_at_utc')->nullable()->index();
            $table->timestamp('accepted_at_utc')->nullable()->index();
            $table->timestamp('ended_at_utc')->nullable()->index();
            $table->timestamp('expires_at_utc')->index();
            $table->string('end_reason', 64)->nullable();
            $table->json('server_metadata')->nullable();
            $table->timestamps();

            $table->foreign('consultation_id')->references('id')->on('appointments')->nullOnDelete();
            $table->foreign('conversation_id')->references('id')->on('conversations')->nullOnDelete();
            $table->foreign('initiated_by_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('ended_by_user_id')->references('id')->on('users')->nullOnDelete();
            $table->index(['consultation_id', 'current_state']);
            $table->index(['conversation_id', 'current_state']);
        });

        Schema::create('call_participants', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('call_session_id')->index();
            $table->uuid('user_id')->index();
            $table->string('role', 16)->index();
            $table->timestamp('joined_at_utc')->nullable();
            $table->timestamp('left_at_utc')->nullable();
            $table->timestamp('last_seen_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('call_session_id')->references('id')->on('call_sessions')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['call_session_id', 'user_id']);
        });

        Schema::create('device_tokens', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('user_id')->index();
            $table->string('provider', 16)->default('FCM')->index();
            $table->string('token', 512)->unique();
            $table->string('platform', 32)->nullable();
            $table->string('device_label', 128)->nullable();
            $table->timestamp('last_seen_at_utc')->nullable()->index();
            $table->timestamp('revoked_at')->nullable()->index();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('actor_user_id')->nullable()->index();
            $table->string('event', 64)->index();
            $table->string('auditable_type', 128)->nullable()->index();
            $table->string('auditable_id', 64)->nullable()->index();
            $table->json('context')->nullable();
            $table->timestamps();

            $table->foreign('actor_user_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('device_tokens');
        Schema::dropIfExists('call_participants');
        Schema::dropIfExists('call_sessions');
        Schema::dropIfExists('message_receipts');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversation_participants');
        Schema::dropIfExists('conversations');
    }
};
