<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Membatasi akses khusus admin (pengelola kos) untuk halaman
 * dashboard web. Penghuni menggunakan aplikasi mobile.
 */
class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user instanceof \App\Models\User || ! $user->isAdmin()) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')
                ->with('error', 'Dashboard web hanya dapat diakses oleh admin. Penghuni silakan menggunakan aplikasi mobile.');
        }

        return $next($request);
    }
}
