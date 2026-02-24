<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void {}

    public function boot(): void
    {
        RateLimiter::for('auth-login', function (Request $request) {
            $email = (string) $request->input('email', '');
            $key = 'login:'.sha1(strtolower($email)).':'.$request->ip();

            return Limit::perMinute(5)->by($key);
        });

        RateLimiter::for('auth-register', fn (Request $request) => Limit::perMinute(3)->by('register:'.$request->ip()));
        RateLimiter::for('auth-refresh', fn (Request $request) => Limit::perMinute(10)->by('refresh:'.$request->ip()));
    }
}
