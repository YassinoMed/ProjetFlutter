<?php

namespace App\Http\Requests\Secretaries;

use Illuminate\Foundation\Http\FormRequest;

class AcceptSecretaryInvitationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'token' => ['required', 'string', 'min:32', 'max:255'],
            'first_name' => ['required', 'string', 'max:120'],
            'last_name' => ['required', 'string', 'max:120'],
            'password' => ['required', 'string', 'min:12', 'max:255'],
            'phone' => ['nullable', 'string', 'max:32'],
        ];
    }
}
