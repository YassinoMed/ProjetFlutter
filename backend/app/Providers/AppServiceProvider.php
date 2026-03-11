<?php

namespace App\Providers;

use App\Services\Documents\Ai\HeuristicDocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use App\Services\Documents\TextExtraction\CompositeDocumentTextExtractor;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(DocumentTextExtractor::class, CompositeDocumentTextExtractor::class);
        $this->app->singleton(DocumentAiAnalyzer::class, HeuristicDocumentAiAnalyzer::class);
    }

    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            $userId = (string) ($request->user()?->id ?? 'guest');
            $key = 'api:'.$userId.':'.$request->ip();

            return Limit::perMinute(120)->by($key);
        });

        RateLimiter::for('auth-login', function (Request $request) {
            $email = (string) $request->input('email', '');
            $key = 'login:'.sha1(strtolower($email)).':'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('auth-register', fn (Request $request) => Limit::perMinute(3)->by('register:'.$request->ip()));
        RateLimiter::for('auth-refresh', fn (Request $request) => Limit::perMinute(10)->by('refresh:'.$request->ip()));
        RateLimiter::for('chat-messages', fn (Request $request) => Limit::perMinute(120)->by('chat:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('webrtc', fn (Request $request) => Limit::perMinute(240)->by('webrtc:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('conversations', fn (Request $request) => Limit::perMinute(60)->by('conversations:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('messages', fn (Request $request) => Limit::perMinute(180)->by('messages:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('calls', fn (Request $request) => Limit::perMinute(60)->by('calls:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('secretaries', fn (Request $request) => Limit::perMinute(30)->by('secretaries:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('documents', fn (Request $request) => Limit::perMinute(30)->by('documents:'.$request->user()?->id.':'.$request->ip()));
        RateLimiter::for('rgpd', fn (Request $request) => Limit::perMinute(10)->by('rgpd:'.$request->user()?->id.':'.$request->ip()));
    }
}
