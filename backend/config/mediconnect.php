<?php

return [
    'presence_freshness_seconds' => (int) env('MEDICONNECT_PRESENCE_FRESHNESS_SECONDS', 90),
    'message_retention_days' => (int) env('MEDICONNECT_MESSAGE_RETENTION_DAYS', 730),
    'call_ring_timeout_seconds' => (int) env('MEDICONNECT_CALL_RING_TIMEOUT_SECONDS', 45),
    'turn' => [
        'stun_urls' => array_values(array_filter(array_map('trim', explode(',', (string) env('COTURN_STUN_URLS', 'stun:stun.l.google.com:19302'))))),
        'turn_urls' => array_values(array_filter(array_map('trim', explode(',', (string) env('COTURN_TURN_URLS', 'turn:coturn:3478?transport=udp,turn:coturn:3478?transport=tcp'))))),
        'username' => env('COTURN_STATIC_USERNAME'),
        'password' => env('COTURN_STATIC_PASSWORD'),
        'shared_secret' => env('COTURN_SHARED_SECRET'),
        'credential_ttl_seconds' => (int) env('COTURN_CREDENTIAL_TTL_SECONDS', 3600),
    ],
];
