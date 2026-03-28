<?php

namespace App\Http\Requests\Teleconsultations;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateTeleconsultationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'appointment_id' => [
                'nullable',
                'uuid',
                'exists:appointments,id',
                'required_without_all:patient_user_id,doctor_user_id,scheduled_starts_at_utc,scheduled_ends_at_utc',
            ],
            'patient_user_id' => ['required_without:appointment_id', 'uuid', 'exists:users,id'],
            'doctor_user_id' => ['required_without:appointment_id', 'uuid', 'exists:users,id'],
            'scheduled_starts_at_utc' => ['required_without:appointment_id', 'date', 'after:now'],
            'scheduled_ends_at_utc' => ['required_without:appointment_id', 'date', 'after:scheduled_starts_at_utc'],
            'call_type' => ['nullable', Rule::in(['VIDEO', 'AUDIO'])],
            'server_metadata' => ['nullable', 'array'],
        ];
    }
}
