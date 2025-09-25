<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('bon_exchanges', function (Blueprint $table): void {
            $table->boolean('username_change')->default(false)->after('invite');
            $table->boolean('remove_hnr')->default(false)->after('username_change');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bon_exchanges', function (Blueprint $table): void {
            $table->dropColumn('username_change');
            $table->dropColumn('remove_hnr');
        });
    }
};
