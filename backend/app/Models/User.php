<?php

namespace App\Models;

use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    use HasFactory;
    use Notifiable;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'email',
        'password',
        'first_name',
        'last_name',
        'phone',
        'role',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'role' => UserRole::class,
        'password' => 'hashed',
    ];

    protected static function booted(): void
    {
        static::creating(function (self $user): void {
            if (empty($user->id)) {
                $user->id = (string) Str::uuid();
            }
        });
    }

    // ── Relationships ────────────────────────────────────────

    public function fcmTokens(): HasMany
    {
        return $this->hasMany(FcmToken::class);
    }

    public function patientProfile(): HasOne
    {
        return $this->hasOne(Patient::class, 'user_id');
    }

    public function doctorProfile(): HasOne
    {
        return $this->hasOne(Doctor::class, 'user_id');
    }

    public function medicalRecords(): HasMany
    {
        return $this->hasMany(MedicalRecordMetadata::class, 'patient_user_id');
    }

    public function uploadedDocuments(): HasMany
    {
        return $this->hasMany(Document::class, 'uploaded_by_user_id');
    }

    public function documentsAsPatient(): HasMany
    {
        return $this->hasMany(Document::class, 'patient_user_id');
    }

    public function documentsAsDoctor(): HasMany
    {
        return $this->hasMany(Document::class, 'doctor_user_id');
    }

    public function appointmentsAsPatient(): HasMany
    {
        return $this->hasMany(Appointment::class, 'patient_user_id');
    }

    public function appointmentsAsDoctor(): HasMany
    {
        return $this->hasMany(Appointment::class, 'doctor_user_id');
    }

    public function consents(): HasMany
    {
        return $this->hasMany(UserConsent::class);
    }

    public function trustedDevices(): HasMany
    {
        return $this->hasMany(TrustedDevice::class);
    }

    public function activeTrustedDevices(): HasMany
    {
        return $this->trustedDevices()->whereNull('revoked_at');
    }

    public function delegationsAsDoctor(): HasMany
    {
        return $this->hasMany(DoctorSecretaryDelegation::class, 'doctor_user_id');
    }

    public function delegationsAsSecretary(): HasMany
    {
        return $this->hasMany(DoctorSecretaryDelegation::class, 'secretary_user_id');
    }

    public function conversations(): HasMany
    {
        return $this->hasMany(ConversationParticipant::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class, 'sender_user_id');
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function e2eeDevices(): HasMany
    {
        return $this->hasMany(UserE2eeDevice::class);
    }
}
