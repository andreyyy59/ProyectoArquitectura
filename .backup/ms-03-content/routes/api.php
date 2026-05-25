<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ContentController;

Route::prefix('content')->group(function () {
    Route::get('/', [ContentController::class, 'index']);
    Route::post('/', [ContentController::class, 'store']);
    Route::get('{uuid}', [ContentController::class, 'show']);
    Route::put('{uuid}', [ContentController::class, 'update']);
    Route::delete('{uuid}', [ContentController::class, 'destroy']);
    Route::post('{uuid}/publish', [ContentController::class, 'publish']);
    Route::post('{uuid}/distribute', [ContentController::class, 'distribute']);
    Route::get('categories', [ContentController::class, 'categories']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-03-content', 'status' => 'healthy']);
});
