<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class EnableBiometricRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'device_id'   => ['required', 'string', 'max:255'],
            'device_name' => ['required', 'string', 'max:255'],
            'platform'    => ['sometimes', 'string', 'in:ios,android'],
        ];
    }

    public function messages(): array
    {
        return [
            'device_id.required'   => "L'identifiant de l'appareil est requis.",
            'device_name.required' => "Le nom de l'appareil est requis.",
            'platform.in'          => "La plateforme doit être ios ou android.",
        ];
    }
}
