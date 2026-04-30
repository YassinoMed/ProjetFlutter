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
    'pdf_ocr_max_pages' => (int) env('DOCUMENTS_PDF_OCR_MAX_PAGES', 3),
    'ai_driver' => env('DOCUMENTS_AI_DRIVER', 'heuristic'),
    'document_chat_driver' => env('DOCUMENTS_DOCUMENT_CHAT_DRIVER', env('DOCUMENTS_AI_DRIVER', 'heuristic')),
    'ai_timeout_seconds' => (int) env('DOCUMENTS_AI_TIMEOUT_SECONDS', 45),
    'ai' => [
        'provider' => env('DOCUMENTS_AI_PROVIDER', 'openai_compatible'),
        'base_url' => env('DOCUMENTS_AI_BASE_URL'),
        'api_key' => env('DOCUMENTS_AI_API_KEY'),
        'model' => env('DOCUMENTS_AI_MODEL'),
        'generate_path' => env('DOCUMENTS_AI_GENERATE_PATH', '/generate'),
        'chat_path' => env('DOCUMENTS_AI_CHAT_PATH', '/chat'),
        'max_new_tokens' => (int) env('DOCUMENTS_AI_MAX_NEW_TOKENS', 1024),
        'temperature' => (float) env('DOCUMENTS_AI_TEMPERATURE', 0.0),
        'top_p' => (float) env('DOCUMENTS_AI_TOP_P', 0.9),
        'repetition_penalty' => (float) env('DOCUMENTS_AI_REPETITION_PENALTY', 1.1),
        'prompt_text_max_chars' => (int) env('DOCUMENTS_AI_PROMPT_TEXT_MAX_CHARS', 2600),
    ],
    'qa' => [
        'max_evidence_lines' => (int) env('DOCUMENTS_QA_MAX_EVIDENCE_LINES', 3),
    ],
];
