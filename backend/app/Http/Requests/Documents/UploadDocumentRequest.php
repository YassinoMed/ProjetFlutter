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
                Rule::requiredIf(
                    in_array($user?->role, [UserRole::DOCTOR, UserRole::ADMIN, UserRole::SECRETARY], true)
                ),
                Rule::prohibitedIf($user?->role === UserRole::PATIENT),
                'nullable',
                'uuid',
                $patientRule,
            ],
            'doctor_user_id' => [
                Rule::prohibitedIf(
                    in_array($user?->role, [UserRole::DOCTOR, UserRole::SECRETARY], true)
                ),
                'nullable',
                'uuid',
                $doctorRule,
            ],
            'document_date_utc' => ['nullable', 'date'],
            'document_type_hint' => ['nullable', Rule::enum(DocumentType::class)],
            'client_ocr_text' => ['nullable', 'string', 'max:50000'],
            'client_ocr_engine' => ['nullable', 'string', 'max:64'],
            'client_ocr_language' => ['nullable', 'string', 'max:12'],
            'client_ocr_confidence' => ['nullable', 'numeric', 'min:0', 'max:1'],
            'client_image_quality_score' => ['nullable', 'numeric', 'min:0', 'max:1'],
            'client_image_width' => ['nullable', 'integer', 'min:1', 'max:20000'],
            'client_image_height' => ['nullable', 'integer', 'min:1', 'max:20000'],
            'client_image_quality_warnings' => ['nullable', 'string', 'max:4000'],
        ];
    }
}
