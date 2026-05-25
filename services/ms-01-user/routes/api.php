<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;

Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('validate-offline', [AuthController::class, 'validateOffline']);

    Route::middleware('jwt.auth')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('refresh', [AuthController::class, 'refresh']);
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('offline-token', [AuthController::class, 'offlineToken']);
    });
});

Route::middleware('jwt.auth')->prefix('users')->group(function () {
    Route::get('/', [UserController::class, 'index']);
    Route::get('{uuid}', [UserController::class, 'show']);
    Route::put('{uuid}', [UserController::class, 'update']);
    Route::post('sync-status', [UserController::class, 'syncStatus']);
    Route::post('{uuid}/mark-synced', [UserController::class, 'markSynced']);
});

Route::get('health', function () {
    return response()->json([
        'service' => 'ms-01-user',
        'status' => 'healthy',
        'timestamp' => now()->toIso8601String(),
    ]);
});
