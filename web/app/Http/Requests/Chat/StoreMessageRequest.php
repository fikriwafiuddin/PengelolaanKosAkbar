<?php

namespace App\Http\Requests\Chat;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi pengiriman pesan chat (API mobile & web admin).
 */
class StoreMessageRequest extends FormRequest
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
            'body' => ['required', 'string', 'max:1000'],
            // Hanya dihormati untuk admin — divalidasi ulang di service.
            'is_announcement' => ['nullable', 'boolean'],
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
            'body.required' => 'Isi pesan wajib diisi.',
            'body.max' => 'Pesan maksimal 1.000 karakter.',
            'is_announcement.boolean' => 'Penanda pengumuman tidak valid.',
        ];
    }
}
