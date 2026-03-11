<?php

namespace App\Http\Requests\Secretaries;

use App\Enums\SecretaryPermission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class InviteSecretaryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email:rfc', 'max:255'],
            'first_name' => ['required', 'string', 'max:120'],
            'last_name' => ['required', 'string', 'max:120'],
            'permissions' => ['required', 'array', 'min:1'],
            'permissions.*' => ['required', Rule::in(SecretaryPermission::values())],
            'expires_in_hours' => ['nullable', 'integer', 'min:1', 'max:168'],
        ];
    }
}
