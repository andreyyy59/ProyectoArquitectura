<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AnalyticsController;

Route::prefix('analytics')->group(function () {
    Route::post('xapi/statement', [AnalyticsController::class, 'storeStatement']);
    Route::post('xapi/statements', [AnalyticsController::class, 'storeStatements']);
    Route::get('xapi/statements', [AnalyticsController::class, 'getStatements']);
    Route::get('progress/{userId}', [AnalyticsController::class, 'userProgress']);
    Route::get('progress/{userId}/content/{contentId}', [AnalyticsController::class, 'contentProgress']);
    Route::get('summary/{userId}', [AnalyticsController::class, 'userSummary']);
    Route::get('aggregated', [AnalyticsController::class, 'aggregatedMetrics']);
    Route::post('sync', [AnalyticsController::class, 'syncXapiStatements']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-07-analytics', 'status' => 'healthy']);
});
