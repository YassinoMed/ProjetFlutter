<?php

namespace App\Http\Requests\Documents;

use App\Enums\DocumentType;
use App\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UploadDocumentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $user = $this->user();
        $patientRule = Rule::exists('users', 'id')->where('role', UserRole::PATIENT->value);
        $doctorRule = Rule::exists('users', 'id')->where('role', UserRole::DOCTOR->value);

        return [
            'title' => ['required', 'string', 'max:160'],
            'file' => [
                'required',
                'file',
                'max:'.(int) config('documents.max_upload_kb', 12288),
                'mimetypes:'.implode(',', config('documents.allowed_mimes', [])),
            ],
            'patient_user_id' => [
                Rule::requiredIf($user?->role === UserRole::DOCTOR || $user?->role === UserRole::ADMIN),
                Rule::prohibitedIf($user?->role === UserRole::PATIENT),
                'nullable',
                'uuid',
                $patientRule,
            ],
            'doctor_user_id' => [
                Rule::prohibitedIf($user?->role === UserRole::DOCTOR),
                'nullable',
                'uuid',
                $doctorRule,
            ],
            'document_date_utc' => ['nullable', 'date'],
            'document_type_hint' => ['nullable', Rule::enum(DocumentType::class)],
        ];
    }
}
