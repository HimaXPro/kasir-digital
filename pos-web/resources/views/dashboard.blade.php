@extends('layouts.app')
@section('title', 'Dashboard')
@section('breadcrumb', 'Dashboard')

@section('content')
<div class="page-header">
<div class="page-header-row">
    <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-sub">Ringkasan aktivitas bisnis hari ini — {{ now()->locale('id')->translatedFormat('l, d F Y') }}</p>
    </div>
    <a href="{{ route('pos.index') }}" class="btn btn-primary btn-lg">
        <svg style="width:16px;height:16px;stroke:#fff;fill:none;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
        Buka Kasir POS
    </a>
</div>
</div>

<!-- KPI Cards -->
<div class="kpi-grid">
    <div class="kpi c-indigo">
        <div class="kpi-top">
            <div class="kpi-label">Transaksi Hari Ini</div>
            <div class="kpi-icon-wrap c-indigo">
                <svg viewBox="0 0 24 24"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
            </div>
        </div>
        <div class="kpi-value">{{ $todaySales }}</div>
        <div class="kpi-badge b-primary">Transaksi Selesai</div>
    </div>

    <div class="kpi c-cyan">
        <div class="kpi-top">
            <div class="kpi-label">Omzet Hari Ini</div>
            <div class="kpi-icon-wrap c-cyan">
                <svg viewBox="0 0 24 24"><path d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
        </div>
        <div class="kpi-value sm">Rp {{ number_format($todayRevenue, 0, ',', '.') }}</div>
        <div class="kpi-badge b-cyan">Total Penjualan</div>
    </div>

    <div class="kpi c-green">
        <div class="kpi-top">
            <div class="kpi-label">Laba Kotor Hari Ini</div>
            <div class="kpi-icon-wrap c-green">
                <svg viewBox="0 0 24 24"><path d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            </div>
        </div>
        <div class="kpi-value sm">Rp {{ number_format($todayProfit, 0, ',', '.') }}</div>
        <div class="kpi-badge b-success">Gross Profit</div>
    </div>

    <div class="kpi c-amber">
        <div class="kpi-top">
            <div class="kpi-label">Produk Terjual</div>
            <div class="kpi-icon-wrap c-amber">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
            </div>
        </div>
        <div class="kpi-value">{{ $itemsSoldToday }}</div>
        <div class="kpi-badge b-warning">Total Item Terjual Hari Ini</div>
    </div>
</div>

<!-- Charts Row -->
<div class="g2 mb-4">
    <div class="card">
        <div class="card-header">
            <span class="card-title">📊 Omzet 7 Hari Terakhir</span>
        </div>
        <div class="card-body">
            <div class="chart-wrap"><canvas id="revenueChart"></canvas></div>
        </div>
    </div>

    <div class="card">
        <div class="card-header">
            <span class="card-title">🏆 Produk Terlaris</span>
        </div>
        <div class="card-body">
            @if($topProducts->isEmpty())
                <div class="empty-state" style="padding:1.5rem"><div class="empty-icon">📦</div><div class="empty-title">Belum ada data</div></div>
            @else
                <div class="chart-wrap mb-3"><canvas id="topChart" style="max-height:170px"></canvas></div>
                @foreach($topProducts as $item)
                <div class="d-flex ai-c jb" style="padding:.35rem 0;border-bottom:1px solid #F1F5F9">
                    <span class="fs-sm truncate" style="max-width:160px;color:var(--text-primary);font-weight:500">{{ $item->product->name ?? '—' }}</span>
                    <span class="badge b-primary">{{ $item->total_qty }} terjual</span>
                </div>
                @endforeach
            @endif
        </div>
    </div>
</div>

<!-- Recent Transactions -->
<div class="card">
    <div class="card-header">
        <span class="card-title">🧾 Transaksi Terbaru</span>
        <a href="{{ route('reports.index') }}" class="btn btn-ghost btn-sm">Lihat Laporan →</a>
    </div>
    <div class="tbl-wrap">
        <table>
            <thead>
                <tr>
                    <th>No. Invoice</th>
                    <th>Waktu</th>
                    <th>Metode Bayar</th>
                    <th class="text-right">Grand Total</th>
                    <th class="text-right">Kembalian</th>
                </tr>
            </thead>
            <tbody>
                @forelse($recentTransactions as $trx)
                <tr>
                    <td><span class="fw-7 text-primary-c">{{ $trx->invoice_number }}</span></td>
                    <td class="text-muted fs-sm">{{ $trx->created_at->format('d M Y · H:i') }}</td>
                    <td><span class="badge b-secondary">{{ strtoupper($trx->payment_method) }}</span></td>
                    <td class="text-right fw-7">Rp {{ number_format($trx->grand_total, 0, ',', '.') }}</td>
                    <td class="text-right text-muted">Rp {{ number_format($trx->change_amount, 0, ',', '.') }}</td>
                </tr>
                @empty
                <tr>
                    <td colspan="5">
                        <div class="empty-state"><div class="empty-icon">🧾</div><div class="empty-title">Belum ada transaksi hari ini</div></div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection

@push('scripts')
<script>
const palette=['rgba(79,70,229,.85)','rgba(6,182,212,.85)','rgba(16,185,129,.85)','rgba(245,158,11,.85)','rgba(239,68,68,.85)'];
const paletteB=['rgba(79,70,229,1)','rgba(6,182,212,1)','rgba(16,185,129,1)','rgba(245,158,11,1)','rgba(239,68,68,1)'];
Chart.defaults.font.family="'Inter',sans-serif";
Chart.defaults.color='#64748B';

// Revenue Chart
new Chart(document.getElementById('revenueChart'),{
    type:'bar',
    data:{
        labels:{!! json_encode($chartDays->pluck('date')) !!},
        datasets:[{
            label:'Omzet',
            data:{!! json_encode($chartDays->pluck('revenue')) !!},
            backgroundColor:'rgba(79,70,229,.12)',
            borderColor:'rgba(79,70,229,.9)',
            borderWidth:2,
            borderRadius:6,
            borderSkipped:false,
        }]
    },
    options:{
        responsive:true,maintainAspectRatio:false,
        plugins:{legend:{display:false},tooltip:{callbacks:{label:c=>' '+fmt(c.raw)}}},
        scales:{
            y:{beginAtZero:true,grid:{color:'rgba(0,0,0,0.04)'},ticks:{callback:v=>'Rp '+new Intl.NumberFormat('id-ID').format(v),font:{size:10}}},
            x:{grid:{display:false},ticks:{font:{size:11}}}
        }
    }
});

// Top Products Doughnut
@if($topProducts->isNotEmpty())
new Chart(document.getElementById('topChart'),{
    type:'doughnut',
    data:{
        labels:{!! json_encode($topProducts->map(fn($i)=>$i->product->name??'Unknown')) !!},
        datasets:[{data:{!! json_encode($topProducts->pluck('total_qty')) !!},backgroundColor:palette,borderColor:'#fff',borderWidth:3}]
    },
    options:{
        responsive:true,maintainAspectRatio:false,
        plugins:{legend:{display:false}},
        cutout:'62%',
    }
});
@endif
</script>
@endpush
