<?php

namespace App\Http\Requests\Devices;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterDeviceTokenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'provider' => ['required', Rule::in(['FCM', 'APNS'])],
            'token' => ['required', 'string', 'min:16', 'max:512'],
            'platform' => ['nullable', 'string', 'max:32'],
            'device_label' => ['nullable', 'string', 'max:128'],
        ];
    }
}
