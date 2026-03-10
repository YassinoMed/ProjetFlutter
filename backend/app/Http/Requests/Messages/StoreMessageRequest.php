<?php

namespace App\Http\Requests\Messages;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'conversation_id' => ['required', 'uuid', 'exists:conversations,id'],
            'client_message_id' => ['nullable', 'string', 'max:128'],
            'message_type' => ['required', Rule::in(['TEXT', 'ATTACHMENT', 'SYSTEM'])],
            'ciphertext' => ['required', 'string', 'max:65535'],
            'nonce' => ['required', 'string', 'max:255'],
            'e2ee_version' => ['required', 'string', 'max:32'],
            'sender_key_id' => ['nullable', 'string', 'max:128'],
            'server_metadata' => ['nullable', 'array'],
            'sent_at_utc' => ['nullable', 'date'],
        ];
    }
}
