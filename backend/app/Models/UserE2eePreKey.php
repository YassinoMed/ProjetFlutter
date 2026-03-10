<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserE2eePreKey extends Model
{
    protected $fillable = [
        'user_e2ee_device_id',
        'key_id',
        'public_key',
        'consumed_at_utc',
    ];

    protected $casts = [
        'consumed_at_utc' => 'datetime',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(UserE2eeDevice::class, 'user_e2ee_device_id');
    }
}
