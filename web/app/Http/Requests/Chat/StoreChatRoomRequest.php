<?php

namespace App\Http\Requests\Chat;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi pembuatan grup chat baru oleh admin (web).
 */
class StoreChatRoomRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:100', 'unique:chat_rooms,name'],
            'description' => ['nullable', 'string', 'max:500'],
            'member_ids' => ['nullable', 'array'],
            'member_ids.*' => ['integer', 'exists:users,id'],
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
            'name.required' => 'Nama grup wajib diisi.',
            'name.max' => 'Nama grup maksimal 100 karakter.',
            'name.unique' => 'Nama grup sudah digunakan.',
            'description.max' => 'Deskripsi maksimal 500 karakter.',
            'member_ids.array' => 'Daftar anggota tidak valid.',
            'member_ids.*.exists' => 'Ada anggota yang tidak ditemukan.',
        ];
    }
}
