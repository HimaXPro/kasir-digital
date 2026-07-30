<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use Illuminate\Support\Facades\DB;

class DashboardApiController extends Controller
{
    /**
     * GET /api/dashboard
     * Mengembalikan semua data KPI dan chart untuk dashboard mobile.
     */
    public function index()
    {
        // ── KPI Hari Ini ───────────────────────────────────────────────
        $todaySales   = Transaction::whereDate('created_at', today())->count();
        $todayRevenue = (float) Transaction::whereDate('created_at', today())->sum('grand_total');
        $itemsSoldToday = (int) TransactionDetail::whereHas('transaction', function ($q) {
            $q->whereDate('transactions.created_at', today());
        })->sum('quantity');

        $todayProfit = (float) (TransactionDetail::whereHas('transaction', function ($q) {
            $q->whereDate('transactions.created_at', today());
        })->selectRaw('COALESCE(SUM((selling_price - cost_price) * quantity), 0) as profit')
          ->value('profit') ?? 0);

        // ── Chart: Omzet 7 Hari Terakhir ────────────────────────────────
        $chartDays = collect(range(6, 0))->map(function ($i) {
            $date = now()->subDays($i);
            return [
                'date'    => $date->format('d M'),
                'revenue' => (float) Transaction::whereDate('created_at', $date)->sum('grand_total'),
            ];
        })->values();

        // ── Chart: Produk Terlaris (Top 5) ──────────────────────────────
        $topProducts = TransactionDetail::select('product_id', DB::raw('SUM(quantity) as total_qty'))
            ->with('product:id,name')
            ->groupBy('product_id')
            ->orderByDesc('total_qty')
            ->limit(5)
            ->get()
            ->map(fn($item) => [
                'product_name' => $item->product->name ?? 'Unknown',
                'total_qty'    => (int) $item->total_qty,
            ]);

        // ── Transaksi Terbaru (10 item) ─────────────────────────────────
        $recentTransactions = Transaction::latest()->limit(10)->get()->map(fn($trx) => [
            'id'             => $trx->id,
            'invoice_number' => $trx->invoice_number,
            'payment_method' => strtoupper($trx->payment_method),
            'grand_total'    => (float) $trx->grand_total,
            'change_amount'  => (float) $trx->change_amount,
            'created_at'     => $trx->created_at->format('d M Y · H:i'),
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'kpi' => [
                    'today_sales'      => $todaySales,
                    'today_revenue'    => $todayRevenue,
                    'today_profit'     => $todayProfit,
                    'items_sold_today' => $itemsSoldToday,
                ],
                'chart_days'          => $chartDays,
                'top_products'        => $topProducts,
                'recent_transactions' => $recentTransactions,
            ],
        ]);
    }
}
