<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
 | Pengingat pembayaran sewa harian: tagihan belum dibayar yang jatuh
 | tempo dalam 5 hari ke depan atau sudah lewat (Sprint 2).
 */
Schedule::command('payments:remind')->dailyAt('08:00');
