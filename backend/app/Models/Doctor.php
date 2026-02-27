<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Doctor extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $primaryKey = 'user_id';

    protected $fillable = [
        'user_id',
        'rpps',
        'specialty',
        'bio',
        'consultation_fee',
        'city',
        'address',
        'latitude',
        'longitude',
        'avatar_url',
        'rating',
        'total_reviews',
        'is_available_for_video',
    ];

    protected $casts = [
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'rating' => 'decimal:2',
        'total_reviews' => 'integer',
        'is_available_for_video' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function schedules(): HasMany
    {
        return $this->hasMany(DoctorSchedule::class, 'doctor_user_id', 'user_id');
    }
}
