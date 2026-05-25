<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AdaptiveController;

Route::prefix('adaptive')->group(function () {
    Route::post('learning-path/generate', [AdaptiveController::class, 'generatePath']);
    Route::get('learning-path/{uuid}', [AdaptiveController::class, 'getPath']);
    Route::get('learning-path/{uuid}/next', [AdaptiveController::class, 'nextActivity']);
    Route::post('learning-path/{uuid}/evaluate', [AdaptiveController::class, 'evaluate']);
    Route::post('progress', [AdaptiveController::class, 'recordProgress']);
    Route::get('recommendations/{userId}', [AdaptiveController::class, 'recommendations']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-05-adaptive', 'status' => 'healthy']);
});
