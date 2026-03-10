<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email'       => ['required', 'email:rfc', 'max:255'],
            'password'    => ['required', 'string', 'max:255'],
            'device_id'   => ['sometimes', 'string', 'max:255'],
            'device_name' => ['sometimes', 'string', 'max:255'],
            'platform'    => ['sometimes', 'string', 'in:ios,android'],
        ];
    }
}
