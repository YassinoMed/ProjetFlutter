<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fcm_tokens', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('user_id')->index();
            $table->string('token', 512)->unique();
            $table->string('platform', 32)->nullable();
            $table->dateTime('last_seen_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fcm_tokens');
    }
};
