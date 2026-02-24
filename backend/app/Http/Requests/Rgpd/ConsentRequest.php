<?php

namespace App\Http\Requests\Rgpd;

use Illuminate\Foundation\Http\FormRequest;

class ConsentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'consent_type' => ['required', 'string', 'max:64'],
            'consented' => ['required', 'boolean'],
        ];
    }
}
