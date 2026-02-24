<?php

namespace App\Http\Requests\WebRtc;

use Illuminate\Foundation\Http\FormRequest;

class WebRtcOfferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'sdp' => ['required', 'string', 'max:8000'],
            'sdp_type' => ['required', 'string', 'in:offer'],
        ];
    }
}
