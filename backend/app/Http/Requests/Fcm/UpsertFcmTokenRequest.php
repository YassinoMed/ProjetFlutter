<?php

namespace App\Http\Requests\Fcm;

use Illuminate\Foundation\Http\FormRequest;

class UpsertFcmTokenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'token' => ['required', 'string', 'min:16', 'max:512'],
            'platform' => ['nullable', 'string', 'max:32'],
        ];
    }
}
