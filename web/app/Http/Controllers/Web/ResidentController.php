<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\ResidentService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Direktori data penghuni di dashboard admin.
 */
class ResidentController extends Controller
{
    public function __construct(private readonly ResidentService $residents)
    {}

    /**
     * GET /residents — halaman Data Penghuni.
     */
    // public function index(Request $request): Response
    // {
    //     $filters = $request->only(['q', 'status', 'with_room']);

    //     return Inertia::render('residents/index', [
    //         'residents' => $this->residents->list($filters),
    //         'filters' => $filters,
    //         'stats' => $this->residents->stats(),
    //     ]);
    // }
    public function index(Request $request): Response
    {
        $filters = $request->only(['q']);

        return Inertia::render('residents/index', [
            'residents' => $this->residents->list($filters),
            'filters' => $filters,
            // 'stats' => $this->residents->stats(),
        ]);
    }
}
