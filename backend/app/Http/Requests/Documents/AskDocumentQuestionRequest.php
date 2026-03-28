<?php

namespace App\Http\Requests\Documents;

use App\Enums\DocumentSummaryAudience;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AskDocumentQuestionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'question' => ['required', 'string', 'min:6', 'max:500'],
            'audience' => ['nullable', Rule::enum(DocumentSummaryAudience::class)],
        ];
    }
}
