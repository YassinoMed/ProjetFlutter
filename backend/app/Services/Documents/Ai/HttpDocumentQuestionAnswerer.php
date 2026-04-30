<?php

namespace App\Services\Documents\Ai;

use App\Enums\DocumentSummaryAudience;
use App\Models\Document;
use App\Models\DocumentExtraction;
use App\Services\Documents\Contracts\DocumentQuestionAnswerer;
use App\Services\Documents\Data\DocumentQuestionAnswerResult;
use App\Services\Documents\Prompts\DocumentPromptFactory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Throwable;

class HttpDocumentQuestionAnswerer implements DocumentQuestionAnswerer
{
    public function __construct(
        private readonly HeuristicGroundedDocumentQuestionAnswerer $fallback,
        private readonly DocumentPromptFactory $prompts,
    ) {}

    public function answer(Document $document, string $question, DocumentSummaryAudience $audience): DocumentQuestionAnswerResult
    {
        $fallbackResult = $this->fallback->answer($document, $question, $audience);

        if (! $this->isConfigured() || $document->latestExtraction === null) {
            return $fallbackResult;
        }

        try {
            $payload = $this->callProvider($document, $question, $audience);

            if ($payload === null) {
                return $fallbackResult;
            }

            return $this->buildResult($payload, $question, $audience, $fallbackResult);
        } catch (Throwable) {
            return $fallbackResult;
        }
    }

    private function isConfigured(): bool
    {
        if ((string) config('documents.ai.provider', 'openai_compatible') === 'medical_api') {
            return trim((string) config('documents.ai.base_url')) !== '';
        }

        return trim((string) config('documents.ai.base_url')) !== ''
            && trim((string) config('documents.ai.model')) !== '';
    }

    private function callProvider(Document $document, string $question, DocumentSummaryAudience $audience): ?array
    {
        if ((string) config('documents.ai.provider', 'openai_compatible') === 'medical_api') {
            return $this->callMedicalApiProvider($document, $question, $audience);
        }

        return $this->callOpenAiCompatibleProvider($document, $question, $audience);
    }

    private function callMedicalApiProvider(Document $document, string $question, DocumentSummaryAudience $audience): ?array
    {
        $response = Http::timeout((int) config('documents.ai_timeout_seconds', 45))
            ->acceptJson()
            ->post($this->endpoint((string) config('documents.ai.chat_path', '/chat')), [
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => $this->prompts->documentQuestionPrompt(),
                    ],
                    [
                        'role' => 'user',
                        'content' => $this->questionPrompt($document, $question, $audience),
                    ],
                ],
                'max_new_tokens' => (int) config('documents.ai.max_new_tokens', 1024),
                'temperature' => (float) config('documents.ai.temperature', 0.0),
                'top_p' => (float) config('documents.ai.top_p', 0.9),
                'repetition_penalty' => (float) config('documents.ai.repetition_penalty', 1.1),
            ]);

        if (! $response->successful()) {
            return null;
        }

        return $this->parseProviderPayload($response->json());
    }

    private function callOpenAiCompatibleProvider(Document $document, string $question, DocumentSummaryAudience $audience): ?array
    {
        $request = Http::timeout((int) config('documents.ai_timeout_seconds', 45))
            ->acceptJson();

        $apiKey = trim((string) config('documents.ai.api_key'));

        if ($apiKey !== '') {
            $request = $request->withToken($apiKey);
        }

        $response = $request->post((string) config('documents.ai.base_url'), [
            'model' => (string) config('documents.ai.model'),
            'temperature' => 0,
            'response_format' => ['type' => 'json_object'],
            'messages' => [
                [
                    'role' => 'system',
                    'content' => $this->prompts->documentQuestionPrompt(),
                ],
                [
                    'role' => 'user',
                    'content' => $this->questionPrompt($document, $question, $audience),
                ],
            ],
        ]);

        if (! $response->successful()) {
            return null;
        }

        return $this->parseProviderPayload($response->json());
    }

    private function questionPrompt(Document $document, string $question, DocumentSummaryAudience $audience): string
    {
        $extraction = $document->latestExtraction;

        if (! $extraction instanceof DocumentExtraction) {
            return 'Question utilisateur: '.$question;
        }

        $textLimit = max(1000, min((int) config('documents.ai.prompt_text_max_chars', 2600), 6000));
        $structuredPayload = is_array($extraction->structured_payload) ? $extraction->structured_payload : [];

        return implode("\n\n", [
            'Contexte: question-reponse sur un document medical patient MediConnect Pro.',
            'Audience: '.$audience->value,
            'Contraintes: reponds uniquement avec le JSON attendu, sans markdown, sans commentaire et sans balise <think>. N utilise que les informations du document.',
            'Champs structures extraits: '.json_encode($structuredPayload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            "Texte OCR/extrait:\n".Str::limit((string) $extraction->normalized_text_encrypted, $textLimit, ''),
            "Question utilisateur:\n".Str::limit($question, 500, ''),
        ]);
    }

    private function endpoint(string $path): string
    {
        return rtrim((string) config('documents.ai.base_url'), '/').'/'.ltrim($path, '/');
    }

    private function parseProviderPayload(mixed $json): ?array
    {
        $content = data_get($json, 'choices.0.message.content')
            ?? data_get($json, 'answer')
            ?? data_get($json, 'output')
            ?? data_get($json, 'response')
            ?? $json;

        if (is_string($content)) {
            return $this->decodeJsonContent($content);
        }

        return is_array($content) ? $content : null;
    }

    private function decodeJsonContent(string $content): ?array
    {
        $content = trim(preg_replace('/```(?:json)?|```/i', '', $content) ?? $content);
        $content = preg_replace('/<think>.*?<\/think>/is', '', $content) ?? $content;
        $content = trim($content);

        if (str_starts_with($content, '<think>')) {
            return null;
        }

        $firstBrace = strpos($content, '{');
        $lastBrace = strrpos($content, '}');

        if ($firstBrace === false || $lastBrace === false || $lastBrace <= $firstBrace) {
            return null;
        }

        $decoded = json_decode(substr($content, $firstBrace, $lastBrace - $firstBrace + 1), true);

        return is_array($decoded) ? $decoded : null;
    }

    private function buildResult(
        array $payload,
        string $question,
        DocumentSummaryAudience $audience,
        DocumentQuestionAnswerResult $fallback,
    ): DocumentQuestionAnswerResult {
        $answer = $this->nullableString($payload['answer'] ?? null);

        if ($answer === null) {
            return $fallback;
        }

        $evidence = $this->evidence($payload['evidence'] ?? []);
        $insufficientEvidence = (bool) ($payload['insufficient_evidence'] ?? ($evidence === []));
        $uncertaintyNotes = $this->stringList($payload['uncertainty_notes'] ?? []);

        if ($insufficientEvidence && $uncertaintyNotes === []) {
            $uncertaintyNotes[] = 'Le modele indique que les preuves documentaires sont insuffisantes.';
        }

        return new DocumentQuestionAnswerResult(
            question: $question,
            audience: $audience,
            answer: $answer,
            insufficientEvidence: $insufficientEvidence,
            evidence: $evidence,
            uncertaintyNotes: $uncertaintyNotes,
            usedStructuredFields: $this->stringList($payload['used_structured_fields'] ?? []),
            confidenceScore: $this->confidence($payload, $fallback),
        );
    }

    private function evidence(mixed $value): array
    {
        if (! is_array($value)) {
            return [];
        }

        return collect($value)
            ->filter(fn (mixed $entry) => is_array($entry))
            ->take((int) config('documents.qa.max_evidence_lines', 3))
            ->map(function (array $entry): array {
                return [
                    'source' => $this->nullableString($entry['source'] ?? null) ?? 'document_ai',
                    'field' => $this->nullableString($entry['field'] ?? null),
                    'excerpt' => Str::limit($this->nullableString($entry['excerpt'] ?? null) ?? '', 600, ''),
                    'certainty' => $this->nullableString($entry['certainty'] ?? null) ?? 'LOW',
                ];
            })
            ->filter(fn (array $entry) => $entry['excerpt'] !== '')
            ->values()
            ->all();
    }

    private function confidence(array $payload, DocumentQuestionAnswerResult $fallback): float
    {
        $value = $payload['confidence_score'] ?? $payload['confidence'] ?? $fallback->confidenceScore ?? 0.5;

        return max(0.0, min((float) $value, 1.0));
    }

    private function stringList(mixed $value): array
    {
        if (is_string($value)) {
            return trim($value) === '' ? [] : [trim($value)];
        }

        if (! is_array($value)) {
            return [];
        }

        return collect($value)
            ->map(fn (mixed $entry) => $this->nullableString($entry))
            ->filter(fn (?string $entry) => $entry !== null)
            ->values()
            ->all();
    }

    private function nullableString(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_scalar($value)) {
            return trim((string) $value) ?: null;
        }

        return null;
    }
}
