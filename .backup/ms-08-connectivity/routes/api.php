<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ConnectivityController;

Route::prefix('connectivity')->group(function () {
    Route::post('heartbeat', [ConnectivityController::class, 'heartbeat']);
    Route::get('status/{edgeNodeId}', [ConnectivityController::class, 'nodeStatus']);
    Route::get('windows/{edgeNodeId}', [ConnectivityController::class, 'syncWindows']);
    Route::post('circuit-breaker/{serviceName}', [ConnectivityController::class, 'circuitBreakerStatus']);
    Route::get('network-map', [ConnectivityController::class, 'networkMap']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-08-connectivity', 'status' => 'healthy']);
});
