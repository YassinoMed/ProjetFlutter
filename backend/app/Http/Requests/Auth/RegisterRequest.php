<?php

namespace App\Http\Requests\Auth;

use App\Enums\ClientPlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterRequest extends FormRequest
{
    protected function prepareForValidation(): void
    {
        $payload = [];

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
            'email' => ['required', 'email:rfc', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'max:255', 'confirmed'],
            'password_confirmation' => ['required', 'string'],
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:32'],
            'role' => ['nullable', 'string', Rule::in(['patient', 'doctor', 'PATIENT', 'DOCTOR'])],
            'speciality' => ['required_if:role,doctor', 'nullable', 'string', 'max:255'],
            'license_number' => ['required_if:role,doctor', 'nullable', 'string', 'max:255'],
            'device_id' => ['sometimes', 'string', 'max:255'],
            'device_uuid' => ['sometimes', 'string', 'max:255'],
            'device_name' => ['sometimes', 'string', 'max:255'],
            'platform' => ['sometimes', 'string', Rule::in(ClientPlatform::values())],
        ];
    }
}
