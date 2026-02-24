<?php

namespace App\Http\Requests\Chat;

use Illuminate\Foundation\Http\FormRequest;

class StoreChatMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ciphertext' => ['required', 'string', 'max:4096'],
            'nonce' => ['required', 'string', 'max:255'],
            'algorithm' => ['required', 'string', 'max:64'],
            'key_id' => ['nullable', 'string', 'max:128'],
            'metadata_encrypted' => ['nullable', 'array'],
        ];
    }
}
