<?php

namespace App\Http\Requests\Secretaries;

use Illuminate\Foundation\Http\FormRequest;

class SwitchDoctorContextRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'doctor_user_id' => ['required', 'uuid', 'exists:users,id'],
        ];
    }
}
