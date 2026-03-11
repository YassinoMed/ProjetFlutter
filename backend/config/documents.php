<?php

return [
    'disk' => env('DOCUMENTS_DISK', 'local'),
    'directory' => env('DOCUMENTS_DIRECTORY', 'medical-documents'),
    'max_upload_kb' => (int) env('DOCUMENTS_MAX_UPLOAD_KB', 12288),
    'allowed_mimes' => [
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
        'text/plain',
    ],
    'pdf_text_driver' => env('DOCUMENTS_PDF_TEXT_DRIVER', 'pdftotext'),
    'ocr_driver' => env('DOCUMENTS_OCR_DRIVER', 'none'),
    'ocr_languages' => env('DOCUMENTS_OCR_LANGUAGES', 'fra+eng'),
    'ai_driver' => env('DOCUMENTS_AI_DRIVER', 'heuristic'),
    'ai_timeout_seconds' => (int) env('DOCUMENTS_AI_TIMEOUT_SECONDS', 45),
    'ai' => [
        'base_url' => env('DOCUMENTS_AI_BASE_URL'),
        'api_key' => env('DOCUMENTS_AI_API_KEY'),
        'model' => env('DOCUMENTS_AI_MODEL'),
    ],
];
