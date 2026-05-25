<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ReportsController;

Route::prefix('reports')->group(function () {
    Route::get('regional', [ReportsController::class, 'regionalSummary']);
    Route::get('regional/{department}', [ReportsController::class, 'departmentDetail']);
    Route::get('municipality/{municipality}', [ReportsController::class, 'municipalityDetail']);
    Route::get('performance', [ReportsController::class, 'performanceReport']);
    Route::get('connectivity', [ReportsController::class, 'connectivityReport']);
    Route::get('adoption', [ReportsController::class, 'adoptionReport']);
    Route::get('export/{type}', [ReportsController::class, 'export']);
});

Route::get('health', function () {
    return response()->json(['service' => 'ms-09-reports', 'status' => 'healthy']);
});
