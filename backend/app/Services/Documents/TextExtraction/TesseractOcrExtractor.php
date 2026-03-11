<?php

namespace App\Services\Documents\TextExtraction;

use App\Services\Documents\Data\TextExtractionResult;
use RuntimeException;
use Symfony\Component\Process\Process;

class TesseractOcrExtractor
{
    public function extract(string $absolutePath): ?TextExtractionResult
    {
        if ((string) config('documents.ocr_driver') !== 'tesseract') {
            return null;
        }

        if (! $this->binaryExists('tesseract')) {
            return null;
        }

        $process = new Process([
            'tesseract',
            $absolutePath,
            'stdout',
            '-l',
            (string) config('documents.ocr_languages', 'fra+eng'),
        ]);
        $process->setTimeout(60);
        $process->run();

        if (! $process->isSuccessful()) {
            throw new RuntimeException('OCR extraction failed.');
        }

        $rawText = trim($process->getOutput());

        if ($rawText === '') {
            return null;
        }

        return new TextExtractionResult(
            rawText: $rawText,
            normalizedText: preg_replace('/\s+/', ' ', $rawText) ?? $rawText,
            source: 'ocr',
            engine: 'tesseract',
            languageCode: 'fr',
            ocrUsed: true,
            ocrRequired: true,
            confidenceScore: 0.75,
        );
    }

    private function binaryExists(string $binary): bool
    {
        $process = new Process(['which', $binary]);
        $process->run();

        return $process->isSuccessful();
    }
}
