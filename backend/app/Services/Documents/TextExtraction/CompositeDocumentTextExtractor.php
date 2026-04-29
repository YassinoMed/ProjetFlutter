<?php

namespace App\Services\Documents\TextExtraction;

use App\Enums\DocumentProcessingStatus;
use App\Models\Document;
use App\Models\DocumentExtraction;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use App\Services\Documents\Data\TextExtractionResult;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Symfony\Component\Process\Process;

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

            $scannedPdfResult = $this->scannedPdfOcr($absolutePath);

            if ($scannedPdfResult !== null) {
                return $scannedPdfResult;
            }

            $clientOcr = $this->clientOcrFallback($document);

            if ($clientOcr !== null) {
                return $clientOcr;
            }

            throw new RuntimeException('No PDF text extractor is available for this server.');
        }

        if (str_starts_with($mime, 'image/')) {
            $ocrResult = $this->ocrExtractor->extract($absolutePath);

            if ($ocrResult !== null) {
                return $ocrResult;
            }

            $clientOcr = $this->clientOcrFallback($document);

            if ($clientOcr !== null) {
                return $clientOcr;
            }

            throw new RuntimeException('No OCR engine is available for scanned images.');
        }

        throw new RuntimeException('Unsupported document format for extraction.');
    }

    private function clientOcrFallback(Document $document): ?TextExtractionResult
    {
        /** @var DocumentExtraction|null $extraction */
        $extraction = $document
            ->extractions()
            ->where('source', 'client_ocr')
            ->where('status', DocumentProcessingStatus::COMPLETED->value)
            ->orderByDesc('version')
            ->first();

        if ($extraction === null) {
            return null;
        }

        $rawText = trim((string) $extraction->raw_text_encrypted);

        if ($rawText === '') {
            return null;
        }

        return new TextExtractionResult(
            rawText: $rawText,
            normalizedText: preg_replace('/\s+/', ' ', $rawText) ?? $rawText,
            source: 'client_ocr',
            engine: $extraction->engine ?: 'flutter_mlkit_text_recognition',
            languageCode: $extraction->language_code,
            ocrUsed: true,
            ocrRequired: true,
            confidenceScore: min((float) ($extraction->confidence_score ?? 0.55), 0.72),
            meta: array_merge($extraction->meta ?? [], [
                'fallback_used' => true,
                'server_ocr_available' => false,
            ]),
        );
    }

    private function scannedPdfOcr(string $absolutePath): ?TextExtractionResult
    {
        if ((string) config('documents.ocr_driver') !== 'tesseract') {
            return null;
        }

        if (! $this->binaryExists('pdftoppm') || ! $this->binaryExists('tesseract')) {
            return null;
        }

        $maxPages = max(1, min((int) config('documents.pdf_ocr_max_pages', 3), 10));
        $tmpDir = storage_path('app/tmp/pdf-ocr/'.(string) Str::uuid());

        if (! mkdir($tmpDir, 0700, true) && ! is_dir($tmpDir)) {
            throw new RuntimeException('Unable to prepare scanned PDF OCR workspace.');
        }

        try {
            $pagePrefix = $tmpDir.'/page';
            $process = new Process([
                'pdftoppm',
                '-png',
                '-r',
                '180',
                '-f',
                '1',
                '-l',
                (string) $maxPages,
                $absolutePath,
                $pagePrefix,
            ]);
            $process->setTimeout(90);
            $process->run();

            if (! $process->isSuccessful()) {
                throw new RuntimeException('Scanned PDF image conversion failed.');
            }

            $pages = glob($tmpDir.'/page-*.png') ?: [];
            sort($pages);

            if ($pages === []) {
                return null;
            }

            $texts = [];
            $scores = [];

            foreach ($pages as $pagePath) {
                $ocrResult = $this->ocrExtractor->extract($pagePath);

                if ($ocrResult === null || trim($ocrResult->normalizedText) === '') {
                    continue;
                }

                $texts[] = trim($ocrResult->rawText);

                if ($ocrResult->confidenceScore !== null) {
                    $scores[] = $ocrResult->confidenceScore;
                }
            }

            $rawText = trim(implode("\n\n", $texts));

            if ($rawText === '') {
                return null;
            }

            return new TextExtractionResult(
                rawText: $rawText,
                normalizedText: preg_replace('/\s+/', ' ', $rawText) ?? $rawText,
                source: 'pdf_ocr',
                engine: 'pdftoppm+tesseract',
                languageCode: 'fr',
                ocrUsed: true,
                ocrRequired: true,
                confidenceScore: $scores === [] ? 0.68 : min(array_sum($scores) / count($scores), 0.78),
                meta: [
                    'scanned_pdf_ocr' => true,
                    'pages_limit' => $maxPages,
                    'pages_converted' => count($pages),
                    'pages_with_text' => count($texts),
                    'conversion_dpi' => 180,
                ],
            );
        } finally {
            foreach (glob($tmpDir.'/*') ?: [] as $file) {
                if (is_file($file)) {
                    @unlink($file);
                }
            }

            if (is_dir($tmpDir)) {
                @rmdir($tmpDir);
            }
        }
    }

    private function binaryExists(string $binary): bool
    {
        $process = new Process(['which', $binary]);
        $process->run();

        return $process->isSuccessful();
    }
}
