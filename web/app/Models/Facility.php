<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

/**
 * Fasilitas kamar (AC, WiFi, kamar mandi dalam, ...).
 *
 * @property int $id
 * @property string $name
 */
#[Fillable(['name'])]
class Facility extends Model
{
    /** @use HasFactory<\Database\Factories\FacilityFactory> */
    use HasFactory;

    /**
     * Kamar-kamar yang memiliki fasilitas ini.
     */
    public function rooms(): BelongsToMany
    {
        return $this->belongsToMany(Room::class, 'room_facility');
    }
}
