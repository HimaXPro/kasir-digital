<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\ReportController;

// Endpoint Transaksi & Laporan
Route::post('/transactions', [TransactionController::class, 'store']);
Route::get('/reports/stock-timeline', [ReportController::class, 'stockTimeline']);
