<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_consents', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('user_id')->index();
            $table->string('consent_type', 64)->index();
            $table->boolean('consented')->default(true);
            $table->dateTime('consented_at_utc')->nullable();
            $table->dateTime('revoked_at_utc')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['user_id', 'consent_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_consents');
    }
};
