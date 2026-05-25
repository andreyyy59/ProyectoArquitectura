<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\NotificationController;

Route::prefix('notifications')->group(function () {
    Route::post('send', [NotificationController::class, 'send']);
    Route::get('{userId}', [NotificationController::class, 'list']);
    Route::put('{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('push/register', [NotificationController::class, 'registerPushToken']);
    Route::post('batch', [NotificationController::class, 'sendBatch']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-10-notifications', 'status' => 'healthy']);
});
