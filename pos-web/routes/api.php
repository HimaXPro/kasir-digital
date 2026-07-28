<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryApiController;
use App\Http\Controllers\Api\DashboardApiController;
use App\Http\Controllers\Api\ProductApiController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Support\Facades\Route;

// ── Auth (publik, tidak perlu token) ──────────────────────────────────
Route::post('/auth/login', [AuthController::class, 'login']);

// ── Protected Routes (wajib pakai token Sanctum) ─────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // Dashboard
    Route::get('/dashboard', [DashboardApiController::class, 'index']);

    // Products
    Route::get('/products',              [ProductApiController::class, 'index']);
    Route::post('/products',             [ProductApiController::class, 'store']);
    Route::put('/products/{product}',    [ProductApiController::class, 'update']);
    Route::delete('/products/{product}', [ProductApiController::class, 'destroy']);

    // Categories
    Route::get('/categories',                [CategoryApiController::class, 'index']);
    Route::post('/categories',               [CategoryApiController::class, 'store']);
    Route::put('/categories/{category}',     [CategoryApiController::class, 'update']);
    Route::delete('/categories/{category}',  [CategoryApiController::class, 'destroy']);

    // Transactions
    Route::post('/transactions', [TransactionController::class, 'store']);

    // Reports
    Route::get('/reports/stock-timeline', [ReportController::class, 'stockTimeline']);
});
