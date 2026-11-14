<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Perlebar kolom data pribadi agar muat teks tersandi PII1:
     * dari aplikasi mobile (amplop RSA-OAEP 344 karakter + payload
     * AES-GCM, total ~450 karakter per field). birth_date tetap
     * date — tidak dienkripsi.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('phone')->nullable()->change();
        });

        Schema::table('residents', function (Blueprint $table) {
            $table->text('identity_number')->nullable()->change();
            $table->text('address')->nullable()->change();
            $table->text('guardian_name')->nullable()->change();
            $table->text('guardian_phone')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 20)->nullable()->change();
        });

        Schema::table('residents', function (Blueprint $table) {
            $table->string('identity_number', 16)->nullable()->change();
            $table->string('address', 500)->nullable()->change();
            $table->string('guardian_name', 150)->nullable()->change();
            $table->string('guardian_phone', 20)->nullable()->change();
        });
    }
};
