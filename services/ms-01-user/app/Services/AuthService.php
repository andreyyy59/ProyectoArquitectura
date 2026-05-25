<?php

namespace App\Services;

use App\Models\User;
use App\Models\OfflineToken;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthService
{
    public function register(array $data): User
    {
        $data['uuid'] = (string) Str::uuid();
        $data['password'] = Hash::make($data['password']);

        if (!isset($data['role_id'])) {
            $data['role_id'] = 1; // Estudiante por defecto
        }

        return User::create($data);
    }

    public function login(string $email, string $password): ?array
    {
        $user = User::where('email', $email)->active()->first();

        if (!$user || !Hash::check($password, $user->password)) {
            return null;
        }

        $token = JWTAuth::fromUser($user);

        $user->update([
            'last_login_at' => now(),
        ]);

        return [
            'token' => $token,
            'token_type' => 'bearer',
            'expires_in' => config('jwt.ttl') * 60,
            'user' => $user->load('role', 'profile'),
        ];
    }

    public function generateOfflineToken(User $user): OfflineToken
    {
        $token = Str::random(48);
        $hash = Hash::make($token);

        $offlineToken = OfflineToken::create([
            'user_id' => $user->id,
            'token_hash' => $hash,
            'expires_at' => now()->addDays(30),
            'issued_at' => now(),
        ]);

        Cache::put(
            "offline_token:{$offlineToken->id}",
            ['user_id' => $user->id, 'token' => $token],
            now()->addDays(30)
        );

        return $offlineToken;
    }

    public function validateOfflineToken(string $token): ?User
    {
        $tokens = OfflineToken::valid()->get();

        foreach ($tokens as $offlineToken) {
            if (Hash::check($token, $offlineToken->token_hash)) {
                $offlineToken->update(['last_validated_at' => now()]);
                return $offlineToken->user;
            }
        }

        return null;
    }

    public function refreshToken(): ?array
    {
        try {
            $newToken = JWTAuth::refresh();
            $user = JWTAuth::setToken($newToken)->authenticate();

            return [
                'token' => $newToken,
                'token_type' => 'bearer',
                'expires_in' => config('jwt.ttl') * 60,
                'user' => $user,
            ];
        } catch (\Exception $e) {
            return null;
        }
    }

    public function getAuthenticatedUser(): ?User
    {
        try {
            return JWTAuth::parseToken()->authenticate();
        } catch (\Exception $e) {
            return null;
        }
    }
}
