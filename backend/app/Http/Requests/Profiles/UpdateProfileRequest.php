<?php

namespace App\Http\Requests\Profiles;

use App\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $user = $this->user();

        $rules = [
            'first_name' => ['sometimes', 'string', 'max:100'],
            'last_name' => ['sometimes', 'string', 'max:100'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
        ];

        if ($user?->role === UserRole::PATIENT) {
            $rules['date_of_birth'] = ['sometimes', 'nullable', 'date'];
            $rules['sex'] = ['sometimes', 'nullable', 'string', 'max:16'];
        }

        if ($user?->role === UserRole::DOCTOR) {
            $rules['rpps'] = [
                'sometimes',
                'nullable',
                'string',
                'max:32',
                Rule::unique('doctors', 'rpps')->ignore($user->id, 'user_id'),
            ];
            $rules['specialty'] = ['sometimes', 'nullable', 'string', 'max:255'];
        }

        return $rules;
    }
}
