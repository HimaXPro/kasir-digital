<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockMutation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function stockTimeline(Request $request)
    {
        // Pilihan rentang: daily, weekly, monthly, yearly
        $period = $request->get('period', 'daily');

        $query = StockMutation::with('product');

        // Filter Rentang Waktu
        if ($period == 'daily') {
            $query->whereDate('created_at', today());
        } elseif ($period == 'weekly') {
            $query->whereBetween('created_at', [now()->subDays(6)->startOfDay(), now()->endOfDay()]);
        } elseif ($period == 'monthly') {
            $query->whereBetween('created_at', [now()->subDays(29)->startOfDay(), now()->endOfDay()]);
        } elseif ($period == 'yearly') {
            $query->whereYear('created_at', now()->year);
        }

        // 1. Ambil List Lini Masa Pergerakan Barang
        $timeline = $query->latest()->get();

        // 2. Agregasi Total Biaya Modal Masuk & Total Nilai Keluar
        $summary = StockMutation::select(
            'type',
            DB::raw('SUM(quantity) as total_qty'),
            DB::raw('SUM(quantity * cost_price) as total_cost_value'), // Biaya Modal
            DB::raw('SUM(quantity * selling_price) as total_selling_value') // Nilai Jual (jika keluar)
        )
            ->when($period == 'daily', fn($q) => $q->whereDate('created_at', today()))
            ->when($period == 'weekly', fn($q) => $q->whereBetween('created_at', [now()->subDays(6)->startOfDay(), now()->endOfDay()]))
            ->when($period == 'monthly', fn($q) => $q->whereBetween('created_at', [now()->subDays(29)->startOfDay(), now()->endOfDay()]))
            ->when($period == 'yearly', fn($q) => $q->whereYear('created_at', now()->year))
            ->groupBy('type')
            ->get()
            ->keyBy('type');

        return response()->json([
            'success' => true,
            'period' => $period,
            'summary' => [
                'stock_in' => [
                    'total_qty' => $summary['in']->total_qty ?? 0,
                    'total_cost' => $summary['in']->total_cost_value ?? 0, // Total Biaya Restock
                ],
                'stock_out' => [
                    'total_qty' => $summary['out']->total_qty ?? 0,
                    'total_cost' => $summary['out']->total_cost_value ?? 0, // Total Modal Terjual
                    'total_revenue' => $summary['out']->total_selling_value ?? 0, // Total Omzet
                    'gross_profit' => ($summary['out']->total_selling_value ?? 0) - ($summary['out']->total_cost_value ?? 0), // Laba Kotor
                ]
            ],
            'timeline' => $timeline
        ]);
    }
}
