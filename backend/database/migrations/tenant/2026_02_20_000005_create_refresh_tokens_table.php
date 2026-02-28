<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('refresh_tokens', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->uuid('user_id')->index();
            $table->char('jti_hash', 64)->unique();
            $table->char('replaced_by_jti_hash', 64)->nullable()->index();

            $table->dateTime('revoked_at_utc')->nullable()->index();
            $table->dateTime('expires_at_utc')->index();

            $table->string('issued_ip', 45)->nullable();
            $table->string('issued_user_agent', 512)->nullable();

            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('refresh_tokens');
    }
};
