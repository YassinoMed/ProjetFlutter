<?php

namespace App\Http\Requests\MedicalRecords;

use App\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreMedicalRecordMetadataRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $user = $this->user();

        $patientRule = Rule::exists('users', 'id')->where('role', UserRole::PATIENT->value);

        return [
            'category' => ['required', 'string', 'max:64'],
            'metadata_encrypted' => ['required', 'array'],
            'recorded_at_utc' => ['required', 'date'],
            'patient_user_id' => [
                Rule::requiredIf($user?->role === UserRole::DOCTOR || $user?->role === UserRole::ADMIN),
                Rule::prohibitedIf($user?->role === UserRole::PATIENT),
                'uuid',
                $patientRule,
            ],
        ];
    }
}
