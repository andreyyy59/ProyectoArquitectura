<?php

namespace App\Http\Middleware;

use Closure;
use Tymon\JWTAuth\Facades\JWTAuth;
use Tymon\JWTAuth\Exceptions\JWTException;
use Tymon\JWTAuth\Exceptions\TokenExpiredException;
use Illuminate\Support\Facades\Cache;

class JwtAuthenticate
{
    public function handle($request, Closure $next)
    {
        try {
            $user = JWTAuth::parseToken()->authenticate();
        } catch (TokenExpiredException $e) {
            return response()->json(['error' => 'Token expirado'], 401);
        } catch (JWTException $e) {
            return response()->json(['error' => 'Token inválido'], 401);
        }

        if (!$user) {
            return response()->json(['error' => 'Usuario no encontrado'], 404);
        }

        return $next($request);
    }
}
