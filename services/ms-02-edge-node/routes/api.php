<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\EdgeNodeController;

Route::prefix('edge-nodes')->group(function () {
    Route::get('/', [EdgeNodeController::class, 'index']);
    Route::post('register', [EdgeNodeController::class, 'register']);
    Route::get('{uuid}', [EdgeNodeController::class, 'show']);
    Route::put('{uuid}', [EdgeNodeController::class, 'update']);
    Route::post('{uuid}/heartbeat', [EdgeNodeController::class, 'heartbeat']);
    Route::get('{uuid}/status', [EdgeNodeController::class, 'status']);
    Route::get('topology', [EdgeNodeController::class, 'topology']);
    Route::post('{uuid}/sync-window', [EdgeNodeController::class, 'setSyncWindow']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-02-edge-node', 'status' => 'healthy']);
});
