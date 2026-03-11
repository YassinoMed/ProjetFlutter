<?php

namespace App\Services\Documents\TextExtraction;

use App\Services\Documents\Data\TextExtractionResult;
use RuntimeException;
use Symfony\Component\Process\Process;

class CliPdfTextExtractor
{
    public function extract(string $absolutePath): ?TextExtractionResult
    {
        if (! $this->binaryExists('pdftotext')) {
            return null;
        }

        $process = new Process(['pdftotext', '-layout', '-enc', 'UTF-8', $absolutePath, '-']);
        $process->setTimeout(30);
        $process->run();

        if (! $process->isSuccessful()) {
            throw new RuntimeException('PDF text extraction failed.');
        }

        $rawText = trim($process->getOutput());

        if ($rawText === '') {
            return null;
        }

        return new TextExtractionResult(
            rawText: $rawText,
            normalizedText: preg_replace('/\s+/', ' ', $rawText) ?? $rawText,
            source: 'native_pdf',
            engine: 'pdftotext',
            languageCode: 'fr',
            confidenceScore: 0.92,
        );
    }

    private function binaryExists(string $binary): bool
    {
        $process = new Process(['which', $binary]);
        $process->run();

        return $process->isSuccessful();
    }
}
