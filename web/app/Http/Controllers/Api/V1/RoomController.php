<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\RoomResource;
use App\Models\Room;
use App\Services\RoomService;
use Illuminate\Http\Request;

/**
 * Katalog & pencarian kamar untuk aplikasi mobile.
 * Endpoint publik — calon penghuni belum login pun bisa melihat katalog.
 */
class RoomController extends Controller
{
    public function __construct(private readonly RoomService $rooms)
    {}

    /**
     * GET /api/v1/rooms — daftar kamar + pencarian & filter.
     *
     * Query: ?q= &type= &status= &max_price= &per_page=
     */
    public function index(Request $request)
    {
        $rooms = $this->rooms->list(
            $request->only(['q', 'type', 'status', 'max_price']),
            (int) $request->query('per_page', '12'),
        );

        return RoomResource::collection($rooms);
    }

    /**
     * GET /api/v1/rooms/{room} — detail satu kamar.
     */
    public function show(Room $room): RoomResource
    {
        return new RoomResource($this->rooms->find($room));
    }
}
