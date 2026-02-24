<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->uuid('id')->primary();

            $table->uuid('patient_user_id')->index();
            $table->uuid('doctor_user_id')->index();

            $table->dateTime('starts_at_utc')->index();
            $table->dateTime('ends_at_utc')->index();

            $table->enum('status', ['DRAFT', 'REQUESTED', 'CONFIRMED', 'CANCELLED', 'COMPLETED'])->index();

            $table->json('metadata_encrypted')->nullable();

            $table->string('cancel_reason')->nullable();

            $table->timestamps();

            $table->foreign('patient_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('doctor_user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->index(['doctor_user_id', 'starts_at_utc']);
            $table->index(['patient_user_id', 'starts_at_utc']);
        });

        Schema::create('appointment_events', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('appointment_id')->index();
            $table->uuid('actor_user_id')->nullable()->index();
            $table->string('from_status', 32)->nullable();
            $table->string('to_status', 32);
            $table->json('metadata_encrypted')->nullable();
            $table->dateTime('occurred_at_utc')->index();

            $table->foreign('appointment_id')->references('id')->on('appointments')->cascadeOnDelete();
            $table->foreign('actor_user_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointment_events');
        Schema::dropIfExists('appointments');
    }
};
