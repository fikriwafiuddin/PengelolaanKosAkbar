<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi pembaruan profil penghuni dari aplikasi mobile
 * (PUT /api/v1/auth/profile). Email & NIK tidak dapat diubah.
 */
class ProfileUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Tanggal maksimal lahir agar usia >= 18 tahun.
     */
    private function maxBirthDate(): string
    {
        return now()->subYears(18)->toDateString();
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'full_name' => ['required', 'string', 'max:150'],
            'phone' => ['required', 'string', 'max:20'],
            'birth_date' => ['required', 'date', 'before_or_equal:'.$this->maxBirthDate()],
            'address' => ['nullable', 'string', 'max:500'],
            'occupation' => ['nullable', 'string', 'max:100'],
            'guardian_name' => ['nullable', 'string', 'max:150'],
            'guardian_phone' => ['required', 'string', 'max:20'],
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
            'full_name.required' => 'Nama lengkap wajib diisi.',
            'phone.required' => 'Nomor HP wajib diisi.',
            'birth_date.required' => 'Tanggal lahir wajib diisi.',
            'birth_date.date' => 'Format tanggal lahir tidak valid.',
            'birth_date.before_or_equal' => 'Usia minimal 18 tahun.',
            'guardian_phone.required' => 'Nomor HP penanggung jawab wajib diisi.',
            'guardian_name.max' => 'Nama penanggung jawab maksimal 150 karakter.',
        ];
    }
}
