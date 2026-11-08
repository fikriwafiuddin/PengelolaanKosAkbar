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
        // Ubah kolom phone di tabel users menjadi VARCHAR(255)
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 255)->nullable()->change();
        });

        // Ubah kolom identity_number dan birth_date di tabel residents menjadi VARCHAR(255)
        Schema::table('residents', function (Blueprint $table) {
            $table->string('identity_number', 255)->nullable()->change();
            $table->string('birth_date', 255)->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
