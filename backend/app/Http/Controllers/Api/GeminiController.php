<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

class GeminiController extends Controller
{
    public function chat(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'prompt' => ['required', 'string', 'min:1', 'max:20000'],
            'temperature' => ['sometimes', 'numeric', 'min:0', 'max:2'],
            'max_tokens' => ['sometimes', 'integer', 'min:1', 'max:4096'],
        ]);

        try {
            $textResult = $this->generateText(
                prompt: $payload['prompt'],
                temperature: (float) ($payload['temperature'] ?? 0.7),
                maxTokens: (int) ($payload['max_tokens'] ?? 900),
            );
        } catch (Throwable) {
            return $this->respondError('Impossible de contacter Gemini.', 502);
        }

        return $this->respondSuccess([
            'type' => 'text',
            'content' => $textResult,
        ], 'Réponse Gemini générée.');
    }

    public function genuiStream(Request $request): JsonResponse|StreamedResponse
    {
        $payload = $request->validate([
            'message' => ['required', 'string', 'min:1', 'max:20000'],
            'system_prompt' => ['required', 'string', 'min:1', 'max:120000'],
            'history' => ['sometimes', 'array', 'max:24'],
            'history.*.role' => ['required_with:history', 'string', 'in:user,assistant,model,system'],
            'history.*.content' => ['required_with:history', 'string', 'max:20000'],
            'context' => ['sometimes', 'array'],
            'temperature' => ['sometimes', 'numeric', 'min:0', 'max:2'],
            'max_tokens' => ['sometimes', 'integer', 'min:1', 'max:8192'],
        ]);

        try {
            $textResult = $this->generateText(
                prompt: $this->buildGenUiPrompt($payload),
                temperature: (float) ($payload['temperature'] ?? 0.35),
                maxTokens: (int) ($payload['max_tokens'] ?? 4096),
            );
        } catch (Throwable) {
            return $this->respondError('Impossible de contacter Gemini pour GenUI.', 502);
        }

        return response()->stream(function () use ($textResult): void {
            foreach (mb_str_split($textResult, 1200) as $chunk) {
                echo 'data: '.json_encode(
                    ['text' => $chunk],
                    JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
                )."\n\n";

                if (ob_get_level() > 0) {
                    ob_flush();
                }
                flush();
            }

            echo "data: [DONE]\n\n";
            if (ob_get_level() > 0) {
                ob_flush();
            }
            flush();
        }, 200, [
            'Cache-Control' => 'no-cache, no-transform',
            'Content-Type' => 'text/event-stream',
            'X-Accel-Buffering' => 'no',
        ]);
    }

    private function generateText(string $prompt, float $temperature, int $maxTokens): string
    {
        $apiKey = trim((string) config('services.gemini.api_key'));
        if ($apiKey === '') {
            throw new \RuntimeException('Clé API Gemini non configurée.');
        }

        $model = (string) config('services.gemini.model', 'gemini-2.5-flash');
        $url = sprintf(
            'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent',
            $model
        );

        $response = Http::timeout((int) config('services.gemini.timeout', 60))
            ->acceptJson()
            ->withHeaders(['Content-Type' => 'application/json'])
            ->post($url.'?key='.$apiKey, [
                'contents' => [
                    [
                        'role' => 'user',
                        'parts' => [
                            ['text' => $prompt],
                        ],
                    ],
                ],
                'generationConfig' => [
                    'temperature' => $temperature,
                    'maxOutputTokens' => $maxTokens,
                ],
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException(
                $response->json('error.message') ?: 'Erreur API Gemini.'
            );
        }

        return $this->extractText($response->json()) ?: 'Pas de réponse.';
    }

    private function buildGenUiPrompt(array $payload): string
    {
        $history = collect($payload['history'] ?? [])
            ->take(-12)
            ->map(fn (array $message): string => sprintf(
                '%s: %s',
                $message['role'],
                $message['content']
            ))
            ->implode("\n\n");

        $context = empty($payload['context'])
            ? null
            : json_encode($payload['context'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        return trim(implode("\n\n", array_filter([
            $payload['system_prompt'],
            'Contexte applicatif courant:',
            $context ?: 'Aucun contexte additionnel fourni.',
            'Historique récent:',
            $history ?: 'Aucun historique.',
            'Dernier message utilisateur:',
            $payload['message'],
            'Réponds avec du texte français bref et, lorsque pertinent, des blocs A2UI JSON valides.',
        ])));
    }

    private function extractText(array $response): ?string
    {
        $parts = data_get($response, 'candidates.0.content.parts', []);
        if (! is_array($parts)) {
            return null;
        }

        $chunks = [];
        foreach ($parts as $part) {
            if (is_array($part) && isset($part['text']) && is_string($part['text'])) {
                $chunks[] = $part['text'];
            }
        }

        return trim(implode("\n", $chunks)) ?: null;
    }
}
