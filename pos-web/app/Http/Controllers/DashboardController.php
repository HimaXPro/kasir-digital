<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        // ── KPI Hari Ini ───────────────────────────────────────────────
        $todaySales   = Transaction::whereDate('created_at', today())->count();
        $todayRevenue = Transaction::whereDate('created_at', today())->sum('grand_total');
        $itemsSoldToday = TransactionDetail::whereHas('transaction', function ($q) {
            $q->whereDate('transactions.created_at', today());
        })->sum('quantity');
        $todayProfit = TransactionDetail::whereHas('transaction', function ($q) {
            $q->whereDate('transactions.created_at', today());
        })->selectRaw('COALESCE(SUM((selling_price - cost_price) * quantity), 0) as profit')
          ->value('profit') ?? 0;

        // ── Chart: Omzet 7 Hari Terakhir ────────────────────────────────
        $chartDays = collect(range(6, 0))->map(function ($i) {
            $date = now()->subDays($i);
            return [
                'date'    => $date->format('d M'),
                'revenue' => (float) Transaction::whereDate('created_at', $date)->sum('grand_total'),
            ];
        });

        // ── Chart: Produk Terlaris (Top 5) ──────────────────────────────
        $topProducts = TransactionDetail::select('product_id', DB::raw('SUM(quantity) as total_qty'))
            ->with('product:id,name')
            ->groupBy('product_id')
            ->orderByDesc('total_qty')
            ->limit(5)
            ->get();

        // ── Transaksi Terbaru (8 item) ──────────────────────────────────
        $recentTransactions = Transaction::latest()->limit(8)->get();

        return view('dashboard', compact(
            'todaySales', 'todayRevenue', 'todayProfit', 'itemsSoldToday',
            'chartDays', 'topProducts', 'recentTransactions'
        ));
    }
}
