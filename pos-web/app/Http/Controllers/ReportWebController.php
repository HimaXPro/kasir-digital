<?php

namespace App\Http\Controllers;

use App\Models\StockMutation;
use App\Models\Transaction;
use Carbon\Carbon;
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

        // ── Hitung range tanggal dengan copy() agar tidak mutasi ──────────
        [$start, $end] = $this->getDateRange($period);

        // ── Summary Stok ──────────────────────────────────────────────────
        $stockSummary = StockMutation::select(
                'type',
                DB::raw('COALESCE(SUM(quantity), 0) as total_qty'),
                DB::raw('COALESCE(SUM(quantity * cost_price), 0) as total_cost'),
                DB::raw('COALESCE(SUM(quantity * selling_price), 0) as total_sell')
            )
            ->whereBetween('created_at', [$start, $end])
            ->groupBy('type')
            ->get()
            ->keyBy('type');

        $stockIn  = $stockSummary->get('in');
        $stockOut = $stockSummary->get('out');

        // ── Summary Transaksi ─────────────────────────────────────────────
        $txSummary = Transaction::whereBetween('created_at', [$start, $end])
            ->selectRaw('COUNT(*) as total_trx, COALESCE(SUM(grand_total), 0) as total_revenue, COALESCE(SUM(discount_amount), 0) as total_discount')
            ->first();

        $grossProfit = ($stockOut->total_sell ?? 0) - ($stockOut->total_cost ?? 0);

        // ── Chart Data ────────────────────────────────────────────────────
        $chartData = $this->buildChartData($period);

        // ── Timeline Mutasi Stok ──────────────────────────────────────────
        $timeline = StockMutation::with('product:id,name,sku')
            ->whereBetween('created_at', [$start, $end])
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn ($m) => [
                'id'             => $m->id,
                'type'           => $m->type,
                'product_name'   => $m->product->name ?? '—',
                'product_sku'    => $m->product->sku  ?? '—',
                'quantity'       => $m->quantity,
                'cost_price'     => (float) $m->cost_price,
                'selling_price'  => (float) $m->selling_price,
                'total_cost'     => (float) ($m->cost_price * $m->quantity),
                'reference_type' => $m->reference_type,
                'notes'          => $m->notes,
                'date'           => $m->created_at->format('d M Y H:i') . ' WIB',
            ]);

        // ── History Transaksi ─────────────────────────────────────────────
        $transactions = Transaction::whereBetween('created_at', [$start, $end])
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn ($t) => [
                'id'             => $t->id,
                'invoice_number' => $t->invoice_number,
                'date'           => $t->created_at->format('d M Y H:i') . ' WIB',
                'payment_method' => $t->payment_method,
                'grand_total'    => (float) $t->grand_total,
                'change_amount'  => (float) $t->change_amount,
            ]);

        return response()->json([
            'summary' => [
                'stock_in'     => ['qty' => (int)($stockIn->total_qty  ?? 0), 'cost' => (float)($stockIn->total_cost  ?? 0)],
                'stock_out'    => ['qty' => (int)($stockOut->total_qty ?? 0), 'cost' => (float)($stockOut->total_cost ?? 0), 'revenue' => (float)($stockOut->total_sell ?? 0)],
                'total_trx'    => (int)($txSummary->total_trx     ?? 0),
                'revenue'      => (float)($txSummary->total_revenue ?? 0),
                'gross_profit' => (float) $grossProfit,
                'discount'     => (float)($txSummary->total_discount ?? 0),
            ],
            'chart'        => $chartData,
            'timeline'     => $timeline,
            'transactions' => $transactions,
        ]);
    }

    /**
     * Kembalikan [start, end] Carbon tanpa mutasi satu sama lain.
     * Selalu gunakan copy() agar tiap operasi independen.
     */
    private function getDateRange(string $period): array
    {
        $now = Carbon::now();   // satu referensi waktu yang konsisten

        return match ($period) {
            'daily'   => [
                $now->copy()->startOfDay(),
                $now->copy()->endOfDay(),
            ],
            'weekly'  => [
                $now->copy()->subDays(6)->startOfDay(),
                $now->copy()->endOfDay(),
            ],
            'monthly' => [
                $now->copy()->subDays(29)->startOfDay(),
                $now->copy()->endOfDay(),
            ],
            'yearly'  => [
                $now->copy()->startOfYear()->startOfDay(),
                $now->copy()->endOfYear()->endOfDay(),
            ],
            default   => [
                $now->copy()->subDays(30)->startOfDay(),
                $now->copy()->endOfDay(),
            ],
        };
    }

    private function buildChartData(string $period): array
    {
        $now = Carbon::now();   // satu referensi, copy() untuk setiap kalkulasi

        if ($period === 'yearly') {
            return collect(range(1, 12))->map(function ($m) use ($now) {
                // copy() agar now tidak termutasi oleh setMonth()
                $label   = $now->copy()->setMonth($m)->format('M');
                $year    = $now->year;
                $revenue = Transaction::whereMonth('created_at', $m)->whereYear('created_at', $year)->sum('grand_total');
                $inQty   = StockMutation::where('type', 'in')->whereMonth('created_at', $m)->whereYear('created_at', $year)->sum('quantity');
                $outQty  = StockMutation::where('type', 'out')->whereMonth('created_at', $m)->whereYear('created_at', $year)->sum('quantity');

                return ['label' => $label, 'revenue' => (float) $revenue, 'in' => (int) $inQty, 'out' => (int) $outQty];
            })->values()->all();
        }

        $days = match ($period) {
            'daily'   => 1,
            'weekly'  => 7,
            'monthly' => 30,
            default   => 7,
        };

        return collect(range($days - 1, 0))->map(function ($i) use ($now, $period) {
            // copy() setiap iterasi agar subDays tidak menumpuk
            $date  = $now->copy()->subDays($i);

            $label = $period === 'weekly' ? $date->isoFormat('dd d/M') : $date->format('d M');

            $revenue = Transaction::whereDate('created_at', $date)->sum('grand_total');
            $inQty   = StockMutation::where('type', 'in')->whereDate('created_at', $date)->sum('quantity');
            $outQty  = StockMutation::where('type', 'out')->whereDate('created_at', $date)->sum('quantity');

            return ['label' => $label, 'revenue' => (float) $revenue, 'in' => (int) $inQty, 'out' => (int) $outQty];
        })->values()->all();
    }
}
