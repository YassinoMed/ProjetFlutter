<?php

namespace App\Http\Requests\Auth;

use App\Enums\ClientPlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class LoginRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        $payload = [];

        if (! $this->filled('login') && $this->filled('email')) {
            $payload['login'] = $this->input('email');
        }

        if (! $this->filled('device_id') && $this->filled('device_uuid')) {
            $payload['device_id'] = $this->input('device_uuid');
        }

        if ($payload !== []) {
            $this->merge($payload);
        }
    }

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'login' => ['required', 'string', 'max:255'],
            'email' => ['sometimes', 'string', 'max:255'],
            'password' => ['required', 'string', 'max:255'],
            'device_id' => ['sometimes', 'string', 'max:255'],
            'device_uuid' => ['sometimes', 'string', 'max:255'],
            'device_name' => ['sometimes', 'string', 'max:255'],
            'platform' => ['sometimes', 'string', Rule::in(ClientPlatform::values())],
        ];
    }
}
