<?php

namespace App\Models;

use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use PHPOpenSourceSaver\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
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

    public function getJWTIdentifier(): mixed
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims(): array
    {
        return [];
    }

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
}
