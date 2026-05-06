<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
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

        $apiKey = trim((string) config('services.gemini.api_key'));
        if ($apiKey === '') {
            return $this->respondError('Clé API Gemini non configurée.', 500);
        }

        $model = (string) config('services.gemini.model', 'gemini-1.5-flash');
        $url = sprintf(
            'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent',
            $model
        );

        try {
            $response = Http::timeout((int) config('services.gemini.timeout', 60))
                ->acceptJson()
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url.'?key='.$apiKey, [
                    'contents' => [
                        [
                            'role' => 'user',
                            'parts' => [
                                ['text' => $payload['prompt']],
                            ],
                        ],
                    ],
                    'generationConfig' => [
                        'temperature' => (float) ($payload['temperature'] ?? 0.7),
                        'maxOutputTokens' => (int) ($payload['max_tokens'] ?? 900),
                    ],
                ]);
        } catch (Throwable) {
            return $this->respondError('Impossible de contacter Gemini.', 502);
        }

        if (! $response->successful()) {
            return $this->respondError(
                $response->json('error.message') ?: 'Erreur API Gemini.',
                $response->status() >= 400 && $response->status() < 500 ? 422 : 502,
            );
        }

        $textResult = $response->json('candidates.0.content.parts.0.text') ?: 'Pas de réponse.';

        return $this->respondSuccess([
            'type' => 'text',
            'content' => $textResult,
        ], 'Réponse Gemini générée.');
    }
}
