<?php

namespace App\Models;

use App\Enums\CallType;
use App\Enums\TeleconsultationStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Teleconsultation extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'appointment_id',
        'conversation_id',
        'current_call_session_id',
        'patient_user_id',
        'doctor_user_id',
        'created_by_user_id',
        'call_type',
        'status',
        'session_reference',
        'scheduled_starts_at_utc',
        'scheduled_ends_at_utc',
        'ringing_started_at_utc',
        'started_at_utc',
        'ended_at_utc',
        'expires_at_utc',
        'cancellation_reason',
        'failure_reason',
        'server_metadata',
    ];

    protected $casts = [
        'call_type' => CallType::class,
        'status' => TeleconsultationStatus::class,
        'scheduled_starts_at_utc' => 'datetime',
        'scheduled_ends_at_utc' => 'datetime',
        'ringing_started_at_utc' => 'datetime',
        'started_at_utc' => 'datetime',
        'ended_at_utc' => 'datetime',
        'expires_at_utc' => 'datetime',
        'server_metadata' => 'array',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $teleconsultation): void {
            if (empty($teleconsultation->id)) {
                $teleconsultation->id = (string) Str::uuid();
            }

            if (empty($teleconsultation->session_reference)) {
                $teleconsultation->session_reference = Str::random(40);
            }
        });
    }

    public function appointment(): BelongsTo
    {
        return $this->belongsTo(Appointment::class);
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function currentCallSession(): BelongsTo
    {
        return $this->belongsTo(CallSession::class, 'current_call_session_id');
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'patient_user_id');
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_user_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function participants(): HasMany
    {
        return $this->hasMany(TeleconsultationParticipant::class);
    }

    public function callEvents(): HasMany
    {
        return $this->hasMany(CallEvent::class)->orderByDesc('occurred_at_utc');
    }
}
