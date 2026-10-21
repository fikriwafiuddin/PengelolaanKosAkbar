<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BookingController;
use App\Http\Controllers\Api\V1\ChatController;
use App\Http\Controllers\Api\V1\FacilityController;
use App\Http\Controllers\Api\V1\InvoiceController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\RoomController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| REST API v1 — dikonsumsi aplikasi mobile (Flutter)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {
    /*
     | Endpoint publik — calon penghuni belum login pun bisa
     | melihat katalog, mencari kamar, dan mendaftar.
     */
    Route::post('auth/register', [AuthController::class, 'register'])->name('api.v1.auth.register');
    Route::post('auth/login', [AuthController::class, 'login'])->name('api.v1.auth.login');

    Route::get('rooms', [RoomController::class, 'index'])->name('api.v1.rooms.index');
    Route::get('rooms/{room}', [RoomController::class, 'show'])
        ->whereNumber('room')
        ->name('api.v1.rooms.show');

    Route::get('facilities', [FacilityController::class, 'index'])->name('api.v1.facilities.index');

    /*
     | Endpoint privat — butuh token Sanctum (Bearer token dari login).
     */
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout'])->name('api.v1.auth.logout');
        Route::get('auth/me', [AuthController::class, 'me'])->name('api.v1.auth.me');
        Route::put('auth/profile', [AuthController::class, 'updateProfile'])->name('api.v1.auth.profile.update');

        // Pemesanan kamar (Sprint 2)
        Route::get('bookings', [BookingController::class, 'index'])->name('api.v1.bookings.index');
        Route::post('bookings', [BookingController::class, 'store'])->name('api.v1.bookings.store');

        // Tagihan sewa bulanan (Sprint 2)
        Route::get('invoices', [InvoiceController::class, 'index'])->name('api.v1.invoices.index');
        Route::get('invoices/{invoice}', [InvoiceController::class, 'show'])
            ->whereNumber('invoice')
            ->name('api.v1.invoices.show');

        // Pembayaran sewa: nominal + bukti bayar (Sprint 2)
        Route::post('invoices/{invoice}/payments', [PaymentController::class, 'store'])
            ->whereNumber('invoice')
            ->name('api.v1.payments.store');

        // Notifikasi pengingat pembayaran (Sprint 2)
        Route::get('notifications', [NotificationController::class, 'index'])->name('api.v1.notifications.index');
        Route::post('notifications/mark-read', [NotificationController::class, 'markRead'])->name('api.v1.notifications.markRead');

        // Chat grup & pengumuman (Sprint 3)
        Route::get('chat/rooms', [ChatController::class, 'rooms'])->name('api.v1.chat.rooms');
        Route::get('chat/rooms/{room}/messages', [ChatController::class, 'messages'])
            ->whereNumber('room')
            ->name('api.v1.chat.messages');
        Route::post('chat/rooms/{room}/messages', [ChatController::class, 'store'])
            ->whereNumber('room')
            ->name('api.v1.chat.send');
    });
});
