<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Logika autentikasi untuk aplikasi mobile: registrasi penghuni,
 * login token Sanctum, logout, profil, dan pembaruan profil.
 */
class AuthService
{
    /**
     * Registrasi akun baru + profil identitas penghuni.
     *
     * Akun dibuat dengan status "menunggu_validasi" dan BELUM diberi
     * token — penghuni baru hanya bisa login setelah admin menvalidasi
     * akunnya (alur persetujuan Sprint 1 revisi).
     */
    public function register(array $data): User
    {
        $user = User::create([
            'name' => $data['full_name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => 'penghuni',
            'status' => User::STATUS_PENDING,
            'phone' => $data['phone'] ?? null,
        ]);

        $user->resident()->create([
            'full_name' => $data['full_name'],
            'identity_number' => $data['identity_number'],
            'birth_date' => $data['birth_date'] ?? null,
            'address' => $data['address'] ?? null,
            'occupation' => $data['occupation'] ?? null,
            'guardian_name' => $data['guardian_name'] ?? null,
            'guardian_phone' => $data['guardian_phone'] ?? null,
        ]);

        return $user->load('resident');
    }

    /**
     * Login dengan email + password, terbitkan token baru.
     *
     * Login ditolak bila akun belum divalidasi admin atau ditolak.
     *
     * @return array{user: User, token: string}
     *
     * @throws ValidationException
     */
    public function login(string $email, string $password): array
    {
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => 'Email atau kata sandi salah.',
            ]);
        }

        if ($user->isPending()) {
            throw ValidationException::withMessages([
                'email' => 'Akun Anda masih menunggu validasi admin. Silakan coba lagi setelah akun disetujui.',
            ]);
        }

        if ($user->status === User::STATUS_REJECTED) {
            throw ValidationException::withMessages([
                'email' => 'Registrasi akun Anda ditolak. Silakan hubungi pengelola kos.',
            ]);
        }

        return [
            'user' => $user->load('resident'),
            'token' => $user->createToken('mobile')->plainTextToken,
        ];
    }

    /**
     * Cabut semua token device (logout menyeluruh).
     */
    public function logout(User $user): void
    {
        $user->tokens()->delete();
    }

    /**
     * Profil lengkap user: akun + identitas penghuni + kamar yang disewa.
     */
    public function profile(User $user): User
    {
        return $user->load([
            'resident.activeBooking.room.facilities',
        ]);
    }

    /**
     * Perbarui profil penghuni (data identitas yang boleh diubah).
     * Email dan NIK bersifat tetap dan tidak dapat diubah dari aplikasi.
     */
    public function updateProfile(User $user, array $data): User
    {
        $user->update([
            'name' => $data['full_name'],
            'phone' => $data['phone'],
        ]);

        $user->resident->update([
            'full_name' => $data['full_name'],
            'birth_date' => $data['birth_date'],
            'address' => $data['address'] ?? null,
            'occupation' => $data['occupation'] ?? null,
            'guardian_name' => $data['guardian_name'] ?? null,
            'guardian_phone' => $data['guardian_phone'],
        ]);

        return $this->profile($user->refresh());
    }
}
