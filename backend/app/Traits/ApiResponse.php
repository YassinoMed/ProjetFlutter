<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    /**
     * Build standard success API response.
     */
    protected function respondSuccess(mixed $data = null, ?string $message = null, int $statusCode = 200, ?array $meta = null): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'error' => null,
            'meta' => $meta,
        ], $statusCode);
    }

    /**
     * Build standard error API response.
     */
    protected function respondError(string $message, int $statusCode = 400, mixed $errors = null, ?int $code = null): JsonResponse
    {
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
                'code' => $code ?? $statusCode,
                'errors' => $formattedErrors,
            ],
            'meta' => null,
        ], $statusCode);
    }
}
