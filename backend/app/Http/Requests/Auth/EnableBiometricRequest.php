<?php

namespace App\Http\Requests\Auth;

use App\Enums\ClientPlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class EnableBiometricRequest extends FormRequest
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
            'device_name' => ['required', 'string', 'max:255'],
            'platform' => ['sometimes', 'string', Rule::in(ClientPlatform::values())],
        ];
    }

    public function messages(): array
    {
        return [
            'device_id.required' => "L'identifiant de l'appareil est requis.",
            'device_name.required' => "Le nom de l'appareil est requis.",
            'platform.in' => "La plateforme fournie n'est pas supportée.",
        ];
    }
}
