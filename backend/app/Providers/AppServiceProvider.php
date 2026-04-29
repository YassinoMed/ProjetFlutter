<?php

namespace App\Providers;

use App\Services\Documents\Ai\HeuristicDocumentAiAnalyzer;
use App\Services\Documents\Ai\HeuristicGroundedDocumentQuestionAnswerer;
use App\Services\Documents\Ai\HttpDocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentAiAnalyzer;
use App\Services\Documents\Contracts\DocumentQuestionAnswerer;
use App\Services\Documents\Contracts\DocumentTextExtractor;
use App\Services\Documents\TextExtraction\CompositeDocumentTextExtractor;
use App\Services\Ops\Metrics\QueueMetricsRecorder;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Queue\Events\JobProcessing;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(DocumentTextExtractor::class, CompositeDocumentTextExtractor::class);
        $this->app->singleton(DocumentAiAnalyzer::class, function ($app) {
            return (string) config('documents.ai_driver') === 'http'
                ? $app->make(HttpDocumentAiAnalyzer::class)
                : $app->make(HeuristicDocumentAiAnalyzer::class);
        });
        $this->app->singleton(DocumentQuestionAnswerer::class, HeuristicGroundedDocumentQuestionAnswerer::class);
        $this->app->singleton(QueueMetricsRecorder::class);
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

        Event::listen(JobProcessing::class, fn (JobProcessing $event) => app(QueueMetricsRecorder::class)->onJobProcessing($event));
        Event::listen(JobProcessed::class, fn (JobProcessed $event) => app(QueueMetricsRecorder::class)->onJobProcessed($event));
        Event::listen(JobFailed::class, fn (JobFailed $event) => app(QueueMetricsRecorder::class)->onJobFailed($event));
    }
}
