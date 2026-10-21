<?php

use App\Http\Controllers\Web\ChatController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\PaymentController;
use App\Http\Controllers\Web\ResidentController;
use App\Http\Controllers\Web\RoomController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Rute Web Admin (Dashboard)
|--------------------------------------------------------------------------
| Dashboard web khusus admin (pengelola kos). Penghuni menggunakan
| aplikasi mobile yang terhubung melalui REST API.
*/

Route::redirect('/', '/dashboard');

Route::middleware(['auth', 'verified', 'admin'])->group(function () {
    Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Data kamar: CRUD + cetak katalog
    Route::get('rooms/print', [RoomController::class, 'print'])->name('rooms.print');
    Route::resource('rooms', RoomController::class)->except(['create', 'edit', 'show']);

    // Data penghuni: direktori biodata + validasi akun baru
    Route::get('residents', [ResidentController::class, 'index'])->name('residents.index');
    Route::put('residents/{user}/validation', [ResidentController::class, 'updateStatus'])
        ->whereNumber('user')
        ->name('residents.validation.update');

    // Verifikasi pembayaran sewa + cetak kuitansi (Sprint 2)
    Route::get('payments', [PaymentController::class, 'index'])->name('payments.index');
    Route::get('payments/{payment}/receipt', [PaymentController::class, 'receipt'])
        ->whereNumber('payment')
        ->name('payments.receipt');
    Route::put('payments/{payment}/verification', [PaymentController::class, 'update'])
        ->whereNumber('payment')
        ->name('payments.verification.update');

    // Chat grup & pengumuman resmi (Sprint 3)
    Route::get('chat', [ChatController::class, 'index'])->name('chat.index');
    Route::post('chat/rooms', [ChatController::class, 'storeRoom'])->name('chat.rooms.store');
    Route::post('chat/rooms/{room}/messages', [ChatController::class, 'storeMessage'])
        ->whereNumber('room')
        ->name('chat.messages.store');
});

require __DIR__.'/settings.php';
