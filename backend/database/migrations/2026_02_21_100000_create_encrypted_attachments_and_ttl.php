<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Feature: E2EE Encrypted Attachments + Data Minimization TTL
     */
    public function up(): void
    {
        // ── E2EE Encrypted Attachments ──────────────────────────────
        Schema::create('encrypted_attachments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('owner_user_id')->index();

            // Polymorphic: can be attached to chat_messages, medical_record_metadatas, etc.
            $table->string('attachable_type');  // e.g. App\Models\ChatMessage
            $table->uuid('attachable_id');
            $table->index(['attachable_type', 'attachable_id'], 'attachable_idx');

            $table->string('original_filename');
            $table->string('mime_type', 128);
            $table->unsignedBigInteger('file_size_bytes');
            $table->string('storage_path');          // Path to the encrypted blob on disk

            // E2EE metadata
            $table->text('encrypted_key');            // AES key encrypted with recipient's public key
            $table->string('key_id')->nullable();     // Identifier of the key pair used
            $table->string('nonce', 64);              // IV/nonce for AES-GCM
            $table->string('algorithm', 32)->default('AES-256-GCM');
            $table->string('checksum_sha256', 64);    // Integrity check of encrypted blob

            // Data minimization / RGPD
            $table->timestamp('expires_at')->nullable()->index();

            $table->timestamps();

            $table->foreign('owner_user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // ── Data Minimization: add TTL to existing tables ───────────
        Schema::table('chat_messages', function (Blueprint $table) {
            $table->timestamp('expires_at')->nullable()->after('sent_at_utc')->index();
        });

        Schema::table('medical_record_metadatas', function (Blueprint $table) {
            $table->timestamp('expires_at')->nullable()->after('recorded_at_utc')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('encrypted_attachments');

        Schema::table('chat_messages', function (Blueprint $table) {
            $table->dropColumn('expires_at');
        });

        Schema::table('medical_record_metadatas', function (Blueprint $table) {
            $table->dropColumn('expires_at');
        });
    }
};
