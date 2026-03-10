<?php

namespace App\Http\Requests\Conversations;

use Illuminate\Foundation\Http\FormRequest;

class CreateConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'participant_user_id' => ['required', 'uuid', 'exists:users,id'],
            'consultation_id' => ['nullable', 'uuid', 'exists:appointments,id'],
        ];
    }
}
