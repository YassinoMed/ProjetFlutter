<?php

namespace App\Http\Requests\Secretaries;

use Illuminate\Foundation\Http\FormRequest;

class SuspendSecretaryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason' => ['nullable', 'string', 'max:255'],
        ];
    }
}
