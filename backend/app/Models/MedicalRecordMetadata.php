<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Support\Str;

class MedicalRecordMetadata extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    protected $table = 'medical_record_metadatas';

    protected $fillable = [
        'id',
        'patient_user_id',
        'doctor_user_id',
        'category',
        'metadata_encrypted',
        'recorded_at_utc',
        'expires_at',
    ];

    protected $casts = [
        'metadata_encrypted' => 'array',
        'recorded_at_utc' => 'datetime',
        'expires_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $record): void {
            if (empty($record->id)) {
                $record->id = (string) Str::uuid();
            }
            // RGPD Data Minimization: auto-set TTL for medical records
            if ($record->expires_at === null) {
                $ttlDays = (int) env('MEDICAL_RECORD_TTL_DAYS', 3650); // 10 years
                if ($ttlDays > 0) {
                    $record->expires_at = now()->addDays($ttlDays);
                }
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

    /**
     * E2EE encrypted file attachments (ordonnances, résultats labo…).
     */
    public function attachments(): MorphMany
    {
        return $this->morphMany(EncryptedAttachment::class, 'attachable');
    }

    /**
     * Scope: only non-expired records.
     */
    public function scopeActive($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('expires_at')
              ->orWhere('expires_at', '>', now());
        });
    }
}
