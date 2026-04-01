<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('doctors')) {
            return;
        }

        Schema::table('doctors', function (Blueprint $table) {
            if (! Schema::hasColumn('doctors', 'is_approved')) {
                $table->boolean('is_approved')->default(false)->after('specialty');
            }

            if (! Schema::hasColumn('doctors', 'is_rejected')) {
                $table->boolean('is_rejected')->default(false)->after('is_approved');
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('doctors')) {
            return;
        }

        Schema::table('doctors', function (Blueprint $table) {
            $columns = [];

            if (Schema::hasColumn('doctors', 'is_approved')) {
                $columns[] = 'is_approved';
            }

            if (Schema::hasColumn('doctors', 'is_rejected')) {
                $columns[] = 'is_rejected';
            }

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
