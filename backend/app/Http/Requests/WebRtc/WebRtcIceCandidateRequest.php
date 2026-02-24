<?php

namespace App\Http\Requests\WebRtc;

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
            'candidate' => ['required', 'string', 'max:4000'],
            'sdp_mid' => ['nullable', 'string', 'max:128'],
            'sdp_mline_index' => ['nullable', 'integer', 'min:0', 'max:10'],
        ];
    }
}
