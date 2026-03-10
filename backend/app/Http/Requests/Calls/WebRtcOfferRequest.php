<?php

namespace App\Http\Requests\Calls;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class WebRtcOfferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'target_user_id' => ['required', 'uuid', 'exists:users,id'],
            'sdp' => ['required', 'array'],
            'sdp.type' => ['required', Rule::in(['offer'])],
            'sdp.sdp' => ['required', 'string', 'max:65535'],
        ];
    }
}
