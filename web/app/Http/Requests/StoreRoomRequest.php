<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi data kamar untuk tambah & ubah (dipakai web admin).
 */
class StoreRoomRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->isAdmin();
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $roomId = $this->route('room')?->id ?? 'NULL';

        return [
            'room_number' => ['required', 'string', 'max:10', "unique:rooms,room_number,{$roomId}"],
            'type' => ['required', 'string', 'max:50'],
            'price_monthly' => ['required', 'numeric', 'min:0'],
            'status' => ['required', 'in:kosong,terisi,terbooking'],
            'description' => ['nullable', 'string', 'max:1000'],
            'facility_ids' => ['nullable', 'array'],
            'facility_ids.*' => ['integer', 'exists:facilities,id'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'room_number.required' => 'Nomor kamar wajib diisi.',
            'room_number.unique' => 'Nomor kamar sudah terdaftar.',
            'type.required' => 'Tipe kamar wajib dipilih.',
            'price_monthly.required' => 'Harga sewa per bulan wajib diisi.',
            'price_monthly.numeric' => 'Harga harus berupa angka.',
            'status.required' => 'Status kamar wajib dipilih.',
            'status.in' => 'Status kamar tidak valid.',
        ];
    }
}
