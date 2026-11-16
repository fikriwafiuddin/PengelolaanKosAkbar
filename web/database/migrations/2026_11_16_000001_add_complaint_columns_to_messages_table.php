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
        Schema::table('messages', function (Blueprint $table) {
            $table->boolean('is_complaint')->default(false)->after('is_announcement');
            $table->string('complaint_category', 100)->nullable()->after('is_complaint');
            $table->string('complaint_status', 50)->nullable()->after('complaint_category');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropColumn(['is_complaint', 'complaint_category', 'complaint_status']);
        });
    }
};

