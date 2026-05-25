<?php

return [
    'default' => env('DB_CONNECTION', 'mysql'),

    'connections' => [
        'mysql' => [
            'driver' => 'mysql',
            'host' => env('DB_HOST', 'mysql-user'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'educonnect_users'),
            'username' => env('DB_USERNAME', 'educonnect'),
            'password' => env('DB_PASSWORD', 'secret'),
            'unix_socket' => env('DB_SOCKET', ''),
            'charset' => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'prefix' => '',
            'prefix_indexes' => true,
            'strict' => true,
            'engine' => 'InnoDB',
        ],
    ],

    'redis' => [
        'client' => env('REDIS_CLIENT', 'predis'),
        'default' => [
            'host' => env('REDIS_HOST', 'redis'),
            'password' => env('REDIS_PASSWORD'),
            'port' => env('REDIS_PORT', 6379),
            'database' => env('REDIS_DB', 0),
            'prefix' => env('REDIS_PREFIX', 'educonnect_user:'),
        ],
        'cache' => [
            'host' => env('REDIS_HOST', 'redis'),
            'password' => env('REDIS_PASSWORD'),
            'port' => env('REDIS_PORT', 6379),
            'database' => env('REDIS_CACHE_DB', 1),
            'prefix' => 'educonnect_cache:',
        ],
    ],
];
