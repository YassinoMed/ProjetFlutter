<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
        then: function () {
            Route::middleware([
                'web',
            ])
                ->prefix('admin')
                ->name('admin.')
                ->group(base_path('routes/admin.php'));
        },
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->append(\App\Http\Middleware\SecurityHeadersMiddleware::class);
        $middleware->append(\App\Http\Middleware\SanitizeInputMiddleware::class);
        $middleware->append(\App\Http\Middleware\TraceRequestMiddleware::class);
        $middleware->append(\App\Http\Middleware\TenantMiddleware::class);
        $middleware->alias([
            'admin' => \App\Http\Middleware\AdminMiddleware::class,
            'doctor.context' => \App\Http\Middleware\ResolveDoctorDelegationContext::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->render(function (\Throwable $e, \Illuminate\Http\Request $request) {
            if ($request->is('api/*') || $request->wantsJson()) {
                $statusCode = $e instanceof \Symfony\Component\HttpKernel\Exception\HttpExceptionInterface ? $e->getStatusCode() : 500;
                $message = $e->getMessage() ?: 'Server Error';
                $errors = null;

                if ($e instanceof \Illuminate\Validation\ValidationException) {
                    $statusCode = 422;
                    $errors = $e->errors();
                    $message = $e->getMessage();
                } elseif ($e instanceof \Illuminate\Auth\AuthenticationException) {
                    $statusCode = 401;
                    $message = 'Unauthenticated';
                } elseif ($e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException) {
                    $statusCode = 404;
                    $message = 'Resource not found';
                }

                $formattedErrors = null;
                if (is_array($errors)) {
                    $formattedErrors = collect($errors)->mapWithKeys(function ($value, $key) {
                        return [$key => is_array($value) ? $value : [$value]];
                    })->toArray();
                }

                return response()->json([
                    'success' => false,
                    'message' => $message,
                    'data' => null,
                    'error' => [
                        'message' => $message,
                        'code' => $statusCode,
                        'errors' => $formattedErrors,
                    ],
                    'meta' => null,
                ], $statusCode);
            }
        });
    })->create();
