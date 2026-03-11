<?php

namespace App\Services\Documents\TextExtraction;

use App\Models\Document;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use App\Services\Documents\Data\TextExtractionResult;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class CompositeDocumentTextExtractor implements DocumentTextExtractor
{
    public function __construct(
        private readonly CliPdfTextExtractor $pdfExtractor,
        private readonly TesseractOcrExtractor $ocrExtractor,
    ) {}

    public function extract(Document $document): TextExtractionResult
    {
        $absolutePath = Storage::disk($document->storage_disk)->path($document->storage_path);
        $mime = strtolower($document->mime_type);
        $extension = strtolower((string) $document->file_extension);

        if (str_starts_with($mime, 'text/') || $extension === 'txt') {
            $rawText = trim((string) file_get_contents($absolutePath));

            if ($rawText === '') {
                throw new RuntimeException('Document is empty or unreadable.');
            }

            return new TextExtractionResult(
                rawText: $rawText,
                normalizedText: preg_replace('/\s+/', ' ', $rawText) ?? $rawText,
                source: 'plain_text',
                engine: 'native',
                languageCode: 'fr',
                confidenceScore: 1.0,
            );
        }

        if ($mime === 'application/pdf' || $extension === 'pdf') {
            $nativeResult = $this->pdfExtractor->extract($absolutePath);

            if ($nativeResult !== null) {
                return $nativeResult;
            }

            throw new RuntimeException('No PDF text extractor is available for this server.');
        }

        if (str_starts_with($mime, 'image/')) {
            $ocrResult = $this->ocrExtractor->extract($absolutePath);

            if ($ocrResult !== null) {
                return $ocrResult;
            }

            throw new RuntimeException('No OCR engine is available for scanned images.');
        }

        throw new RuntimeException('Unsupported document format for extraction.');
    }
}
