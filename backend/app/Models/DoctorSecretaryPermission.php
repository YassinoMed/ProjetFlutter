<?php

namespace App\Models;

use App\Enums\SecretaryPermission;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DoctorSecretaryPermission extends Model
{
    protected $fillable = [
        'delegation_id',
        'permission',
    ];

    protected $casts = [
        'permission' => SecretaryPermission::class,
    ];

    public function delegation(): BelongsTo
    {
        return $this->belongsTo(DoctorSecretaryDelegation::class, 'delegation_id');
    }
}
