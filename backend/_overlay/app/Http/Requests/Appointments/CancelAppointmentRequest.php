<?php

namespace App\Http\Requests\Appointments;

use Illuminate\Foundation\Http\FormRequest;

class CancelAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cancel_reason' => ['nullable', 'string', 'max:255'],
            'metadata_encrypted' => ['nullable', 'array'],
        ];
    }
}
