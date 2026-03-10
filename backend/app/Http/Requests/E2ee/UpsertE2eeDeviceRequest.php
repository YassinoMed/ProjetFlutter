<?php

namespace App\Http\Requests\E2ee;

use Illuminate\Foundation\Http\FormRequest;

class UpsertE2eeDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'device_id' => ['required', 'string', 'max:128'],
            'device_label' => ['nullable', 'string', 'max:128'],
            'bundle_version' => ['required', 'string', 'max:16'],
            'identity_key_algorithm' => ['required', 'string', 'max:32'],
            'identity_key_public' => ['required', 'string', 'max:16384'],
            'signed_pre_key_id' => ['required', 'string', 'max:128'],
            'signed_pre_key_public' => ['required', 'string', 'max:16384'],
            'signed_pre_key_signature' => ['required', 'string', 'max:16384'],
            'one_time_pre_keys' => ['nullable', 'array'],
            'one_time_pre_keys.*.key_id' => ['required_with:one_time_pre_keys', 'string', 'max:128'],
            'one_time_pre_keys.*.public_key' => ['required_with:one_time_pre_keys', 'string', 'max:16384'],
        ];
    }
}
