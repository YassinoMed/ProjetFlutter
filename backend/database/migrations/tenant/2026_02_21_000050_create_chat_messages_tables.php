<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_messages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('consultation_id')->index();
            $table->uuid('sender_user_id')->index();
            $table->uuid('recipient_user_id')->index();
            $table->string('ciphertext', 4096);
            $table->string('nonce', 255);
            $table->string('algorithm', 64);
            $table->string('key_id', 128)->nullable();
            $table->json('metadata_encrypted')->nullable();
            $table->dateTime('sent_at_utc')->index();
            $table->timestamps();

            $table->foreign('consultation_id')->references('id')->on('appointments')->cascadeOnDelete();
            $table->foreign('sender_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('recipient_user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->index(['consultation_id', 'sent_at_utc']);
        });

        Schema::create('chat_message_statuses', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('message_id')->index();
            $table->uuid('user_id')->index();
            $table->enum('status', ['SENT', 'DELIVERED', 'READ'])->index();
            $table->dateTime('status_at_utc')->index();

            $table->foreign('message_id')->references('id')->on('chat_messages')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->unique(['message_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_message_statuses');
        Schema::dropIfExists('chat_messages');
    }
};
