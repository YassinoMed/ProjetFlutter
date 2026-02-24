<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patients', function (Blueprint $table) {
            $table->uuid('user_id')->primary();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->date('date_of_birth')->nullable();
            $table->string('sex', 16)->nullable();

            $table->timestamps();
        });

        Schema::create('doctors', function (Blueprint $table) {
            $table->uuid('user_id')->primary();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();

            $table->string('rpps', 32)->nullable()->unique();
            $table->string('specialty')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('doctors');
        Schema::dropIfExists('patients');
    }
};
