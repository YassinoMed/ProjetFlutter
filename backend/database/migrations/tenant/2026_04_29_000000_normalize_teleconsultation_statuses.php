<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('teleconsultations')) {
            return;
        }

        DB::table('teleconsultations')
            ->where('status', 'ringing')
            ->update(['status' => 'waiting']);

        DB::table('teleconsultations')
            ->where('status', 'completed')
            ->update(['status' => 'ended']);

        DB::table('teleconsultations')
            ->whereIn('status', ['missed', 'failed'])
            ->update(['status' => 'expired']);
    }

    public function down(): void
    {
        if (! Schema::hasTable('teleconsultations')) {
            return;
        }

        DB::table('teleconsultations')
            ->where('status', 'waiting')
            ->update(['status' => 'ringing']);

        DB::table('teleconsultations')
            ->where('status', 'ended')
            ->update(['status' => 'completed']);
    }
};
