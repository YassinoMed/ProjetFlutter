<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->extendUserRoleEnum();

        Schema::create('doctor_secretary_delegations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('doctor_user_id')->index();
            $table->uuid('secretary_user_id')->nullable()->index();
            $table->uuid('invited_by_user_id')->index();
            $table->uuid('revoked_by_user_id')->nullable()->index();
            $table->string('invited_email')->index();
            $table->string('invited_first_name', 120)->nullable();
            $table->string('invited_last_name', 120)->nullable();
            $table->string('status', 32)->default('PENDING')->index();
            $table->timestamp('activated_at_utc')->nullable()->index();
            $table->timestamp('suspended_at_utc')->nullable()->index();
            $table->timestamp('revoked_at_utc')->nullable()->index();
            $table->timestamp('last_used_at_utc')->nullable()->index();
            $table->string('suspension_reason', 255)->nullable();
            $table->string('revocation_reason', 255)->nullable();
            $table->json('context_snapshot')->nullable();
            $table->timestamps();

            $table->foreign('doctor_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('secretary_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('invited_by_user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('revoked_by_user_id')->references('id')->on('users')->nullOnDelete();
            $table->unique(['doctor_user_id', 'invited_email']);
        });

        Schema::create('doctor_secretary_permissions', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->uuid('delegation_id')->index();
            $table->string('permission', 64)->index();
            $table->timestamps();

            $table->foreign('delegation_id')->references('id')->on('doctor_secretary_delegations')->cascadeOnDelete();
            $table->unique(['delegation_id', 'permission']);
        });

        Schema::create('secretary_invitations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('delegation_id')->index();
            $table->uuid('created_by_user_id')->index();
            $table->string('email')->index();
            $table->string('token_hash', 255)->unique();
            $table->string('status', 32)->default('PENDING')->index();
            $table->timestamp('expires_at_utc')->index();
            $table->timestamp('accepted_at_utc')->nullable()->index();
            $table->timestamp('revoked_at_utc')->nullable()->index();
            $table->timestamps();

            $table->foreign('delegation_id')->references('id')->on('doctor_secretary_delegations')->cascadeOnDelete();
            $table->foreign('created_by_user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::table('audit_logs', function (Blueprint $table) {
            $table->string('actor_role', 32)->nullable()->after('actor_user_id');
            $table->uuid('acting_doctor_user_id')->nullable()->after('actor_role')->index();
            $table->uuid('delegation_id')->nullable()->after('acting_doctor_user_id')->index();
            $table->string('ip_address', 64)->nullable()->after('delegation_id');
            $table->string('user_agent', 255)->nullable()->after('ip_address');

            $table->foreign('acting_doctor_user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('delegation_id')->references('id')->on('doctor_secretary_delegations')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('audit_logs', function (Blueprint $table) {
            $table->dropForeign(['acting_doctor_user_id']);
            $table->dropForeign(['delegation_id']);
            $table->dropColumn([
                'actor_role',
                'acting_doctor_user_id',
                'delegation_id',
                'ip_address',
                'user_agent',
            ]);
        });

        Schema::dropIfExists('secretary_invitations');
        Schema::dropIfExists('doctor_secretary_permissions');
        Schema::dropIfExists('doctor_secretary_delegations');
    }

    private function extendUserRoleEnum(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'sqlite') {
            return;
        }

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE users MODIFY role ENUM('PATIENT','DOCTOR','ADMIN','SECRETARY') NOT NULL");

            return;
        }

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('PATIENT','DOCTOR','ADMIN','SECRETARY'))");
        }
    }
};
