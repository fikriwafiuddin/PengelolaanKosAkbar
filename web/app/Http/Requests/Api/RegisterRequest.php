<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi registrasi akun penghuni baru dari aplikasi mobile.
 *
 * Aturan bisnis (revisi Sprint 1):
 * - NIK harus tepat 16 digit angka.
 * - Usia minimal 18 tahun saat mendaftar.
 * - Kontak penanggung jawab wajib diisi untuk komunikasi cepat.
 */
class RegisterRequest extends FormRequest
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
            // Data akun
            'email' => ['required', 'email', 'max:150', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],

            // Profil identitas penghuni
            'full_name' => ['required', 'string', 'max:150'],
            'identity_number' => ['required', 'digits:16'],
            'phone' => ['required', 'string', 'max:20'],
            'birth_date' => ['required', 'date', 'before_or_equal:'.$this->maxBirthDate()],
            'address' => ['nullable', 'string', 'max:500'],
            'occupation' => ['nullable', 'string', 'max:100'],

            // Kontak penanggung jawab
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
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email sudah terdaftar.',
            'password.required' => 'Kata sandi wajib diisi.',
            'password.min' => 'Kata sandi minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi kata sandi tidak cocok.',
            'full_name.required' => 'Nama lengkap wajib diisi.',
            'identity_number.required' => 'Nomor identitas (NIK) wajib diisi.',
            'identity_number.digits' => 'NIK harus tepat 16 digit angka.',
            'phone.required' => 'Nomor HP wajib diisi.',
            'birth_date.required' => 'Tanggal lahir wajib diisi.',
            'birth_date.date' => 'Format tanggal lahir tidak valid.',
            'birth_date.before_or_equal' => 'Usia minimal 18 tahun untuk mendaftar.',
            'guardian_phone.required' => 'Nomor HP penanggung jawab wajib diisi.',
            'guardian_name.max' => 'Nama penanggung jawab maksimal 150 karakter.',
        ];
    }
}
