<?php

return [
    'title' => 'MediConnect Pro API',
    'description' => 'API REST + WebSocket pour MediConnect Pro.',
    'base_url' => env('APP_URL', 'http://localhost:8080'),
    'routes' => [
        'match' => [
            'prefixes' => ['api/*'],
            'domains' => ['*'],
        ],
    ],
    'auth' => [
        'enabled' => true,
        'default' => 'bearer',
        'in' => 'header',
        'name' => 'Authorization',
        'use_value' => 'Bearer {token}',
    ],
    'output' => [
        'path' => 'public/docs',
    ],
];
