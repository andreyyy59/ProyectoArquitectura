<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AuthService;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(private AuthService $authService) {}

    public function register(Request $request)
    {
        $validated = $request->validate([
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'document_id' => 'nullable|string|max:50',
            'phone' => 'nullable|string|max:20',
            'role_id' => 'nullable|exists:roles,id',
        ]);

        $user = $this->authService->register($validated);

        return $this->success([
            'user' => $user->load('role'),
            'message' => 'Usuario registrado exitosamente',
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $result = $this->authService->login($validated['email'], $validated['password']);

        if (!$result) {
            return $this->error('Credenciales inválidas', 401);
        }

        return $this->success($result);
    }

    public function me()
    {
        $user = $this->authService->getAuthenticatedUser();

        if (!$user) {
            return $this->error('No autenticado', 401);
        }

        return $this->success([
            'user' => $user->load('role', 'profile'),
        ]);
    }

    public function refresh()
    {
        $result = $this->authService->refreshToken();

        if (!$result) {
            return $this->error('No se pudo refrescar el token', 401);
        }

        return $this->success($result);
    }

    public function logout()
    {
        try {
            JWTAuth::invalidate(JWTAuth::getToken());
            return $this->success(['message' => 'Sesión cerrada exitosamente']);
        } catch (\Exception $e) {
            return $this->error('Error al cerrar sesión', 500);
        }
    }

    public function offlineToken(Request $request)
    {
        $user = $this->authService->getAuthenticatedUser();

        if (!$user) {
            return $this->error('No autenticado', 401);
        }

        $offlineToken = $this->authService->generateOfflineToken($user);

        return $this->success([
            'offline_token' => Cache::get("offline_token:{$offlineToken->id}")['token'],
            'expires_at' => $offlineToken->expires_at,
        ]);
    }

    public function validateOffline(Request $request)
    {
        $validated = $request->validate([
            'offline_token' => 'required|string',
        ]);

        $user = $this->authService->validateOfflineToken($validated['offline_token']);

        if (!$user) {
            return $this->error('Token offline inválido o expirado', 401);
        }

        $jwt = JWTAuth::fromUser($user);

        return $this->success([
            'token' => $jwt,
            'user' => $user->load('role'),
        ]);
    }
}
