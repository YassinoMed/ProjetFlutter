<?php

namespace App\Models;

use App\Enums\AppointmentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Appointment extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'patient_user_id',
        'doctor_user_id',
        'starts_at_utc',
        'ends_at_utc',
        'status',
        'metadata_encrypted',
        'cancel_reason',
    ];

    protected $casts = [
        'starts_at_utc' => 'datetime',
        'ends_at_utc' => 'datetime',
        'status' => AppointmentStatus::class,
        'metadata_encrypted' => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $appointment): void {
            if (empty($appointment->id)) {
                $appointment->id = (string) Str::uuid();
            }
        });
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'patient_user_id');
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_user_id');
    }

    public function events(): HasMany
    {
        return $this->hasMany(AppointmentEvent::class);
    }
}
