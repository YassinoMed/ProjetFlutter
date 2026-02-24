<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppointmentEvent extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'appointment_id',
        'actor_user_id',
        'from_status',
        'to_status',
        'metadata_encrypted',
        'occurred_at_utc',
    ];

    protected $casts = [
        'metadata_encrypted' => 'array',
        'occurred_at_utc' => 'datetime',
    ];

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }
}
