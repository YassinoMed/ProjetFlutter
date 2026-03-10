<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_e2ee_devices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id')->index();
            $table->string('device_id', 128);
            $table->string('device_label', 128)->nullable();
            $table->string('bundle_version', 16)->default('1');
            $table->string('identity_key_algorithm', 32)->default('X25519');
            $table->text('identity_key_public');
            $table->string('signed_pre_key_id', 128);
            $table->text('signed_pre_key_public');
            $table->text('signed_pre_key_signature');
            $table->timestamp('last_seen_at_utc')->nullable()->index();
            $table->timestamp('revoked_at')->nullable()->index();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->unique(['user_id', 'device_id']);
        });

        Schema::create('user_e2ee_pre_keys', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('user_e2ee_device_id')->index();
            $table->string('key_id', 128);
            $table->text('public_key');
            $table->timestamp('consumed_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('user_e2ee_device_id')->references('id')->on('user_e2ee_devices')->cascadeOnDelete();
            $table->unique(['user_e2ee_device_id', 'key_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_e2ee_pre_keys');
        Schema::dropIfExists('user_e2ee_devices');
    }
};
