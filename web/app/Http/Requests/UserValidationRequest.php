<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi aksi admin menyetujui / menolak akun penghuni
 * (PUT /residents/{user}/validation).
 */
class UserValidationRequest extends FormRequest
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
        return [
            'status' => ['required', 'in:aktif,ditolak'],
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
            'status.required' => 'Status validasi wajib dipilih.',
            'status.in' => 'Status validasi tidak valid (hanya aktif atau ditolak).',
        ];
    }
}
