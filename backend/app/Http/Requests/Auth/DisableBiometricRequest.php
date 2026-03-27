<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class DisableBiometricRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        if (! $this->filled('device_id') && $this->filled('device_uuid')) {
            $this->merge([
                'device_id' => $this->input('device_uuid'),
            ]);
        }
    }

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'device_id' => ['required', 'string', 'max:255'],
            'device_uuid' => ['sometimes', 'string', 'max:255'],
        ];
    }
}
