<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi pemesanan kamar dari aplikasi mobile: pilih kamar,
 * tanggal mulai sewa, dan durasi sewa dalam bulan.
 */
class StoreBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'room_id' => ['required', 'integer', 'exists:rooms,id'],
            'start_date' => ['required', 'date', 'after_or_equal:today'],
            'duration_months' => ['required', 'integer', 'between:1,12'],
            'note' => ['nullable', 'string', 'max:500'],
        ];
    }

    /**
     * Pesan error dalam bahasa Indonesia.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'room_id.required' => 'Kamar wajib dipilih.',
            'room_id.exists' => 'Kamar tidak ditemukan.',
            'start_date.required' => 'Tanggal mulai sewa wajib diisi.',
            'start_date.date' => 'Format tanggal mulai sewa tidak valid.',
            'start_date.after_or_equal' => 'Tanggal mulai sewa tidak boleh sebelum hari ini.',
            'duration_months.required' => 'Durasi sewa wajib diisi.',
            'duration_months.integer' => 'Durasi sewa harus berupa jumlah bulan (angka).',
            'duration_months.between' => 'Durasi sewa antara 1 sampai 12 bulan.',
            'note.max' => 'Catatan maksimal 500 karakter.',
        ];
    }
}
