<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\DashboardService;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Dashboard admin web — ringkasan okupansi & aktivitas kos.
 */
class DashboardController extends Controller
{
    public function __construct(private readonly DashboardService $dashboard)
    {}

    /**
     * GET /dashboard
     */
    public function index(): Response
    {
        return Inertia::render('dashboard', [
            'overview' => $this->dashboard->overview(),
        ]);
    }
}
