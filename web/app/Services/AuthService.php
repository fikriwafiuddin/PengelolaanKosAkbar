<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Logika autentikasi untuk aplikasi mobile: registrasi penghuni,
 * login token Sanctum, logout, dan profil.
 */
class AuthService
{
    /**
     * Registrasi akun baru + profil identitas penghuni, lalu terbitkan token.
     *
     * @return array{user: User, token: string}
     */
    public function register(array $data): array
    {
        $user = User::create([
            'name' => $data['full_name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => 'penghuni',
            'phone' => $data['phone'] ?? null,
        ]);

        $user->resident()->create([
            'full_name' => $data['full_name'],
            'identity_number' => $data['identity_number'],
            'birth_date' => $data['birth_date'] ?? null,
            'address' => $data['address'] ?? null,
            'occupation' => $data['occupation'] ?? null,
        ]);

        return [
            'user' => $user->load('resident'),
            'token' => $user->createToken('mobile')->plainTextToken,
        ];
    }

    /**
     * Login dengan email + password, terbitkan token baru.
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
}
