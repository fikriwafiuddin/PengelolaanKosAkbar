<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Validasi pengiriman pembayaran sewa dari aplikasi mobile:
 * nominal + metode + bukti transfer (wajib saat metode transfer).
 */
class SubmitPaymentRequest extends FormRequest
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
            'amount' => ['required', 'numeric', 'min:1000'],
            'method' => ['required', 'in:transfer,tunai'],
            'proof' => ['required_if:method,transfer', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
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
            'amount.required' => 'Nominal pembayaran wajib diisi.',
            'amount.numeric' => 'Nominal harus berupa angka.',
            'amount.min' => 'Nominal pembayaran minimal Rp 1.000.',
            'method.required' => 'Metode pembayaran wajib dipilih.',
            'method.in' => 'Metode pembayaran tidak valid.',
            'proof.required_if' => 'Bukti transfer wajib diunggah untuk pembayaran transfer.',
            'proof.image' => 'Bukti bayar harus berupa gambar.',
            'proof.mimes' => 'Bukti bayar harus berformat jpg, jpeg, png, atau webp.',
            'proof.max' => 'Ukuran bukti bayar maksimal 2 MB.',
        ];
    }
}
