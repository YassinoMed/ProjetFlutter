<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Doctor extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $primaryKey = 'user_id';

    protected $fillable = [
        'user_id',
        'rpps',
        'specialty',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
