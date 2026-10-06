<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\FacilityResource;
use App\Models\Facility;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Daftar fasilitas (untuk filter katalog di aplikasi mobile).
 */
class FacilityController extends Controller
{
    /**
     * GET /api/v1/facilities
     */
    public function index(): AnonymousResourceCollection
    {
        return FacilityResource::collection(
            Facility::query()->orderBy('name')->get(),
        );
    }
}
