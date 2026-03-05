<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Default Broadcast Connection
    |--------------------------------------------------------------------------
    |
    | Reverb is a Pusher-protocol-compatible WebSocket server. It uses the
    | 'pusher' broadcast driver, but connects to the local Reverb server
    | instead of Pusher's cloud. This is the recommended config for
    | Laravel 11 + Reverb.
    |
    */
    'default' => env('BROADCAST_CONNECTION', env('APP_ENV') === 'testing' ? 'log' : 'reverb'),

    'connections' => [
        /*
        |----------------------------------------------------------------------
        | Reverb (local Pusher-compatible WebSocket server)
        |----------------------------------------------------------------------
        |
        | IMPORTANT: The driver is 'pusher' (not 'reverb'). Reverb implements
        | the Pusher protocol, so Laravel uses the PusherBroadcaster under
        | the hood. The 'reverb' name is just the connection identifier.
        |
        */
        'reverb' => [
            'driver' => 'pusher',
            'key' => env('REVERB_APP_KEY', ''),
            'secret' => env('REVERB_APP_SECRET', ''),
            'app_id' => env('REVERB_APP_ID', ''),
            'options' => [
                'host' => env('REVERB_HOST', '127.0.0.1'),
                'port' => env('REVERB_PORT', 8080),
                'scheme' => env('REVERB_SCHEME', 'http'),
                'encrypted' => false,
                'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
            ],
        ],

        'redis' => [
            'driver' => 'redis',
            'connection' => 'default',
        ],

        'log' => [
            'driver' => 'log',
        ],

        'null' => [
            'driver' => 'null',
        ],
    ],
];
