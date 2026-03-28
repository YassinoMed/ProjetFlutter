<?php

namespace App\Http\Requests\Teleconsultations;

use Illuminate\Foundation\Http\FormRequest;

class JoinTeleconsultationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'device_label' => ['nullable', 'string', 'max:128'],
            'camera_enabled' => ['nullable', 'boolean'],
            'microphone_enabled' => ['nullable', 'boolean'],
        ];
    }
}
