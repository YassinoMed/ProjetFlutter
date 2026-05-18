<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GeminiGenUiTest extends TestCase
{
    public function test_genui_stream_proxies_gemini_response_as_sse(): void
    {
        config()->set('services.gemini.api_key', 'test-key');
        config()->set('services.gemini.model', 'gemini-2.5-flash');

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent*' => Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                [
                                    'text' => 'Bonjour```json {"version":"v0.9"} ```',
                                ],
                            ],
                        ],
                    ],
                ],
            ]),
        ]);

        $response = $this->post('/api/genui/stream', [
            'message' => 'Prépare un brief',
            'system_prompt' => 'Tu génères des UI A2UI.',
            'history' => [
                ['role' => 'user', 'content' => 'Bonjour'],
            ],
            'context' => ['screen' => 'test'],
        ]);

        $response->assertOk();

        $content = $response->streamedContent();
        $this->assertStringContainsString('data: ', $content);
        $this->assertStringContainsString('"text"', $content);
        $this->assertStringContainsString('data: [DONE]', $content);

        Http::assertSent(fn ($request) => str_contains(
            $request['contents'][0]['parts'][0]['text'],
            'Prépare un brief'
        ) && str_contains(
            $request['contents'][0]['parts'][0]['text'],
            'Tu génères des UI A2UI.'
        ));
    }
}
