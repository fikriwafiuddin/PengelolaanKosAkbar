<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\FacilityController;
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
    });
});
