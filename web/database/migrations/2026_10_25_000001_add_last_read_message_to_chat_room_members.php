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
        Schema::table('chat_room_members', function (Blueprint $table) {
            // Penanda baca terakhir anggota — dasar hitung badge belum
            // dibaca di aplikasi mobile.
            $table->foreignId('last_read_message_id')
                ->nullable()
                ->constrained('messages')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('chat_room_members', function (Blueprint $table) {
            $table->dropConstrainedForeignId('last_read_message_id');
        });
    }
};
