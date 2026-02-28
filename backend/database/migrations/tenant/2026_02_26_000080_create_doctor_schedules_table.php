<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('doctor_schedules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('doctor_user_id')->index();

            // 0 = Sunday, 1 = Monday, …, 6 = Saturday
            $table->unsignedTinyInteger('day_of_week');
            $table->time('start_time');   // e.g. 09:00
            $table->time('end_time');     // e.g. 17:00
            $table->unsignedSmallInteger('slot_duration_minutes')->default(30);
            $table->boolean('is_active')->default(true)->index();

            $table->timestamps();

            $table->foreign('doctor_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['doctor_user_id', 'day_of_week', 'start_time'], 'doctor_day_start_unique');
            $table->index(['doctor_user_id', 'day_of_week', 'is_active']);
        });

        // Add more fields to doctors table for richer search
        Schema::table('doctors', function (Blueprint $table) {
            $table->text('bio')->nullable()->after('specialty');
            $table->string('consultation_fee', 32)->nullable()->after('bio');
            $table->string('city', 128)->nullable()->after('consultation_fee');
            $table->string('address')->nullable()->after('city');
            $table->decimal('latitude', 10, 7)->nullable()->after('address');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->string('avatar_url')->nullable()->after('longitude');
            $table->decimal('rating', 3, 2)->nullable()->default(0)->after('avatar_url');
            $table->unsignedInteger('total_reviews')->default(0)->after('rating');
            $table->boolean('is_available_for_video')->default(true)->after('total_reviews');
            $table->index(['specialty', 'city']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('doctor_schedules');

        Schema::table('doctors', function (Blueprint $table) {
            $table->dropColumn([
                'bio', 'consultation_fee', 'city', 'address',
                'latitude', 'longitude', 'avatar_url', 'rating',
                'total_reviews', 'is_available_for_video',
            ]);
        });
    }
};
