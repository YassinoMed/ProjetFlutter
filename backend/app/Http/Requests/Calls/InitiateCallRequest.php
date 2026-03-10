<?php

namespace App\Http\Requests\Calls;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class InitiateCallRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'conversation_id' => ['required', 'uuid', 'exists:conversations,id'],
            'consultation_id' => ['nullable', 'uuid', 'exists:appointments,id'],
            'call_type' => ['required', Rule::in(['VIDEO', 'AUDIO'])],
            'server_metadata' => ['nullable', 'array'],
        ];
    }
}
