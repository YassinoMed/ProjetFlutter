<?php

namespace App\Http\Requests\Calls;

use Illuminate\Foundation\Http\FormRequest;

class WebRtcIceCandidateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'target_user_id' => ['required', 'uuid', 'exists:users,id'],
            'candidate' => ['required', 'array'],
            'candidate.candidate' => ['required', 'string', 'max:4096'],
            'candidate.sdpMid' => ['nullable', 'string', 'max:255'],
            'candidate.sdpMLineIndex' => ['nullable', 'integer', 'min:0'],
            'candidate.usernameFragment' => ['nullable', 'string', 'max:255'],
        ];
    }
}
