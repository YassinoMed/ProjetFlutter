<?php

namespace App\Http\Requests\Teleconsultations;

use Illuminate\Foundation\Http\FormRequest;

class EndTeleconsultationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason' => ['nullable', 'string', 'max:500'],
            'connection_quality' => ['nullable', 'string', 'max:32'],
        ];
    }
}
