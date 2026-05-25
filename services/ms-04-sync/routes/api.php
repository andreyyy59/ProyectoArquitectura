<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\SyncController;

Route::prefix('sync')->group(function () {
    Route::post('initiate', [SyncController::class, 'initiate']);
    Route::post('handshake', [SyncController::class, 'handshake']);
    Route::post('delta/download', [SyncController::class, 'downloadDelta']);
    Route::post('delta/upload', [SyncController::class, 'uploadChanges']);
    Route::post('resolve-conflicts', [SyncController::class, 'resolveConflicts']);
    Route::get('status/{batchUuid}', [SyncController::class, 'status']);
    Route::get('pending/{edgeNodeId}', [SyncController::class, 'pendingChanges']);
    Route::post('events', [SyncController::class, 'storeEvents']);
    Route::get('checkpoint/{edgeNodeId}', [SyncController::class, 'checkpoint']);
});

Route::get('health', function () {
    return response()->json([
        'service' => 'ms-04-sync',
        'status' => 'healthy',
        'timestamp' => now()->toIso8601String(),
    ]);
});
