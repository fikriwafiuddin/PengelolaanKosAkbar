<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\UserValidationRequest;
use App\Models\User;
use App\Services\ResidentService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Direktori data penghuni (biodata + status akun) dan validasi
 * akun baru oleh admin. Controller tipis — logika di ResidentService.
 */
class ResidentController extends Controller
{
    public function __construct(private readonly ResidentService $residents)
    {}

    /**
     * GET /residents — halaman Data Penghuni (biodata).
     */
    public function index(Request $request): Response
    {
        $filters = $request->only(['q', 'status']);

        return Inertia::render('residents/index', [
            'residents' => $this->residents->list($filters),
            'filters' => $filters,
        ]);
    }

    /**
     * PUT /residents/{user}/validation — setujui / tolak akun penghuni.
     */
    public function updateStatus(UserValidationRequest $request, User $user): RedirectResponse
    {
        $status = $request->validated('status');

        $this->residents->validateAccount($user, $status);

        $message = $status === User::STATUS_ACTIVE
            ? "Akun {$user->name} disetujui dan kini dapat login."
            : "Akun {$user->name} ditolak.";

        return back()->with('success', $message);
    }
}
