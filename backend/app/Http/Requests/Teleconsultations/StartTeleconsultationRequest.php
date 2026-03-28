<?php

namespace App\Http\Requests\Teleconsultations;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StartTeleconsultationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'call_type' => ['nullable', Rule::in(['VIDEO', 'AUDIO'])],
            'server_metadata' => ['nullable', 'array'],
        ];
    }
}
