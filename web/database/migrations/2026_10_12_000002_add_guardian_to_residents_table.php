<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('residents', function (Blueprint $table) {
            // Kontak penanggung jawab untuk komunikasi cepat pengelola <-> keluarga penghuni.
            $table->string('guardian_name', 150)->nullable()->after('occupation');
            $table->string('guardian_phone', 20)->nullable()->after('guardian_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('residents', function (Blueprint $table) {
            $table->dropColumn(['guardian_name', 'guardian_phone']);
        });
    }
};
