<?php

namespace App\Http\Requests\Secretaries;

use App\Enums\SecretaryPermission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSecretaryPermissionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'permissions' => ['required', 'array', 'min:1'],
            'permissions.*' => ['required', Rule::in(SecretaryPermission::values())],
        ];
    }
}
