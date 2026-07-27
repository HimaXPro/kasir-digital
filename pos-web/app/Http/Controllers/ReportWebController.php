<?php

namespace App\Http\Controllers;

use App\Models\StockMutation;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportWebController extends Controller
{
    public function index()
    {
        return view('reports.index');
    }

    /**
     * Endpoint AJAX untuk chart & timeline (dipanggil dari JavaScript)
     */
    public function getData(Request $request)
    {
        $period = $request->get('period', 'daily');

        // ── Query builder helper ─────────────────────────────────────────
        $applyPeriod = function ($query) use ($period) {
            return match ($period) {
                'daily'   => $query->whereDate('created_at', today()),
                'weekly'  => $query->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()]),
                'monthly' => $query->whereMonth('created_at', now()->month)->whereYear('created_at', now()->year),
                'yearly'  => $query->whereYear('created_at', now()->year),
                default   => $query,
            };
        };

        // ── Summary Stok ─────────────────────────────────────────────────
        $stockSummary = StockMutation::select(
                'type',
                DB::raw('SUM(quantity) as total_qty'),
                DB::raw('SUM(quantity * cost_price) as total_cost'),
                DB::raw('SUM(quantity * selling_price) as total_sell')
            )
            ->tap($applyPeriod)
            ->groupBy('type')
            ->get()
            ->keyBy('type');

        $stockIn  = $stockSummary->get('in');
        $stockOut = $stockSummary->get('out');

        // ── Summary Transaksi ────────────────────────────────────────────
        $txSummary = Transaction::tap($applyPeriod)
            ->selectRaw('COUNT(*) as total_trx, COALESCE(SUM(grand_total), 0) as total_revenue, COALESCE(SUM(discount_amount), 0) as total_discount')
            ->first();

        $grossProfit = ($stockOut->total_sell ?? 0) - ($stockOut->total_cost ?? 0);

        // ── Chart: Transaksi per Hari (dalam rentang) ─────────────────────
        $chartData = $this->buildChartData($period);

        // ── Timeline Mutasi Stok ─────────────────────────────────────────
        $timeline = StockMutation::with('product:id,name,sku')
            ->tap($applyPeriod)
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn ($m) => [
                'id'             => $m->id,
                'type'           => $m->type,
                'product_name'   => $m->product->name ?? '—',
                'product_sku'    => $m->product->sku ?? '—',
                'quantity'       => $m->quantity,
                'cost_price'     => (float) $m->cost_price,
                'selling_price'  => (float) $m->selling_price,
                'total_cost'     => (float) ($m->cost_price * $m->quantity),
                'reference_type' => $m->reference_type,
                'notes'          => $m->notes,
                'date'           => $m->created_at->format('d M Y H:i'),
            ]);

        return response()->json([
            'summary' => [
                'stock_in'    => ['qty' => $stockIn->total_qty ?? 0,  'cost' => $stockIn->total_cost ?? 0],
                'stock_out'   => ['qty' => $stockOut->total_qty ?? 0, 'cost' => $stockOut->total_cost ?? 0, 'revenue' => $stockOut->total_sell ?? 0],
                'total_trx'   => $txSummary->total_trx ?? 0,
                'revenue'     => $txSummary->total_revenue ?? 0,
                'gross_profit'=> $grossProfit,
                'discount'    => $txSummary->total_discount ?? 0,
            ],
            'chart'    => $chartData,
            'timeline' => $timeline,
        ]);
    }

    private function buildChartData(string $period): array
    {
        $days = match ($period) {
            'daily'   => 1,
            'weekly'  => 7,
            'monthly' => (int) now()->daysInMonth,
            'yearly'  => 12,
            default   => 7,
        };

        if ($period === 'yearly') {
            return collect(range(1, 12))->map(function ($m) {
                $label   = now()->setMonth($m)->format('M');
                $revenue = Transaction::whereMonth('created_at', $m)->whereYear('created_at', now()->year)->sum('grand_total');
                $inQty   = StockMutation::where('type', 'in')->whereMonth('created_at', $m)->whereYear('created_at', now()->year)->sum('quantity');
                $outQty  = StockMutation::where('type', 'out')->whereMonth('created_at', $m)->whereYear('created_at', now()->year)->sum('quantity');
                return ['label' => $label, 'revenue' => (float) $revenue, 'in' => (int) $inQty, 'out' => (int) $outQty];
            })->values()->all();
        }

        return collect(range($days - 1, 0))->map(function ($i) use ($period) {
            $date  = $period === 'daily' ? now() : now()->subDays($i);
            $label = $period === 'daily' ? now()->format('d M') : $date->format('d M');

            $revenue = Transaction::whereDate('created_at', $date)->sum('grand_total');
            $inQty   = StockMutation::where('type', 'in')->whereDate('created_at', $date)->sum('quantity');
            $outQty  = StockMutation::where('type', 'out')->whereDate('created_at', $date)->sum('quantity');

            return ['label' => $label, 'revenue' => (float) $revenue, 'in' => (int) $inQty, 'out' => (int) $outQty];
        })->values()->all();
    }
}
