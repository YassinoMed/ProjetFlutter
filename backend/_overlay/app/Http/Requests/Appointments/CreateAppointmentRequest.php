<?php

namespace App\Http\Requests\Appointments;

use Illuminate\Foundation\Http\FormRequest;

class CreateAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'doctor_user_id' => ['required', 'uuid'],
            'starts_at_utc' => ['required', 'date'],
            'ends_at_utc' => ['required', 'date'],
            'metadata_encrypted' => ['nullable', 'array'],
        ];
    }
}
