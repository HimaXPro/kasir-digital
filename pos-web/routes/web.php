<?php

use App\Http\Controllers\CategoryController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\PosController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ReportWebController;
use Illuminate\Support\Facades\Route;

// ── Redirect root → dashboard ────────────────────────────────────────
Route::get('/', fn () => redirect()->route('dashboard'));

// ── Dashboard ────────────────────────────────────────────────────────
Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

// ── Kasir POS ────────────────────────────────────────────────────────
Route::get('/pos', [PosController::class, 'index'])->name('pos.index');
Route::post('/pos/transactions', [\App\Http\Controllers\Api\TransactionController::class, 'store'])->name('pos.transactions');

// ── Produk ────────────────────────────────────────────────────────────
Route::resource('/products', ProductController::class)->except(['show']);

// ── Kategori ─────────────────────────────────────────────────────────
Route::resource('/categories', CategoryController::class)->except(['show', 'create', 'edit']);

// ── Laporan ──────────────────────────────────────────────────────────
Route::get('/reports', [ReportWebController::class, 'index'])->name('reports.index');
Route::get('/reports/data', [ReportWebController::class, 'getData'])->name('reports.data');
