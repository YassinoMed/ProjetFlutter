<?php

return [
    'stun_urls' => env('COTURN_STUN_URLS', 'stun:stun.l.google.com:19302'),
    'turn_urls' => env('COTURN_TURN_URLS', ''),
    'static_username' => env('COTURN_STATIC_USERNAME'),
    'static_password' => env('COTURN_STATIC_PASSWORD'),
    'shared_secret' => env('COTURN_SHARED_SECRET'),
    'credential_ttl_seconds' => (int) env('COTURN_CREDENTIAL_TTL_SECONDS', 3600),
];
