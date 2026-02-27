<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class DoctorSchedule extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'doctor_user_id',
        'day_of_week',
        'start_time',
        'end_time',
        'slot_duration_minutes',
        'is_active',
    ];

    protected $casts = [
        'day_of_week' => 'integer',
        'slot_duration_minutes' => 'integer',
        'is_active' => 'boolean',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $schedule): void {
            if (empty($schedule->id)) {
                $schedule->id = (string) Str::uuid();
            }
        });
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_user_id');
    }
}
