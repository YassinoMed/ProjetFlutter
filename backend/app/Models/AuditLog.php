<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AuditLog extends Model
{
    protected $fillable = [
        'actor_user_id',
        'actor_role',
        'acting_doctor_user_id',
        'delegation_id',
        'event',
        'auditable_type',
        'auditable_id',
        'ip_address',
        'user_agent',
        'context',
    ];

    protected $casts = [
        'context' => 'array',
    ];

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }

    public function actingDoctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'acting_doctor_user_id');
    }

    public function delegation(): BelongsTo
    {
        return $this->belongsTo(DoctorSecretaryDelegation::class, 'delegation_id');
    }
}
