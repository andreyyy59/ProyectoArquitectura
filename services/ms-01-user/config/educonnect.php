<?php

return [
    'network_type' => env('NETWORK_TYPE', '2G'),
    'circuit_breaker_threshold' => env('CIRCUIT_BREAKER_THRESHOLD', 5),
    'circuit_breaker_timeout' => env('CIRCUIT_BREAKER_TIMEOUT', 30000),
    'sync_batch_size' => env('SYNC_BATCH_SIZE', 50),
    'heartbeat_interval' => env('SYNC_HEARTBEAT_INTERVAL', 30),
];
