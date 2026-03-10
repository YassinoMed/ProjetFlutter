<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trusted_devices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('device_id', 255)->comment('Identifiant unique appareil (device_info_plus)');
            $table->string('device_name', 255)->comment('Nom lisible ex: iPhone 15 Pro');
            $table->string('platform', 50)->default('unknown')->comment('ios / android');
            $table->boolean('biometrics_enabled')->default(false);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamp('revoked_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();

            // Un utilisateur ne peut avoir qu'un seul enregistrement par device_id actif
            $table->unique(['user_id', 'device_id']);

            $table->index(['user_id', 'revoked_at']);
            $table->index('device_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trusted_devices');
    }
};
