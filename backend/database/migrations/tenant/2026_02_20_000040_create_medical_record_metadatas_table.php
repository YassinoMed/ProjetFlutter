<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('medical_record_metadatas', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('patient_user_id')->index();
            $table->uuid('doctor_user_id')->nullable()->index();

            $table->string('category', 64)->index();
            $table->json('metadata_encrypted');

            $table->dateTime('recorded_at_utc')->index();
            $table->timestamps();

            $table->foreign('patient_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('doctor_user_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('medical_record_metadatas');
    }
};
