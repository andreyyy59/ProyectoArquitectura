<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Cache;

class OfflineCacheMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        if ($response->isSuccessful() && $request->isMethod('GET')) {
            $cacheKey = 'api:' . md5($request->fullUrl());

            Cache::store('redis')->put(
                $cacheKey,
                $response->getContent(),
                now()->addHours(24)
            );
        }

        return $response;
    }
}
