@extends('layouts.app')
@section('title', 'Laporan & Statistik')
@section('breadcrumb', 'Laporan & Statistik')

@section('content')
<div class="page-header">
<div class="page-header-row">
    <div>
        <h1 class="page-title">📊 Laporan & Statistik</h1>
        <p class="page-sub">Timeline pergerakan stok, omzet, dan laba kotor bisnis Anda</p>
    </div>
    <div class="period-tabs">
        <button class="period-tab on" data-p="daily"   onclick="setPeriod('daily',this)">Harian</button>
        <button class="period-tab"    data-p="weekly"  onclick="setPeriod('weekly',this)">Mingguan</button>
        <button class="period-tab"    data-p="monthly" onclick="setPeriod('monthly',this)">Bulanan</button>
        <button class="period-tab"    data-p="yearly"  onclick="setPeriod('yearly',this)">Tahunan</button>
    </div>
</div>
</div>

<!-- Summary Cards -->
<div class="kpi-grid" id="kpiGrid">
    <div class="kpi c-cyan">
        <div class="kpi-top">
            <div class="kpi-label">Stok Masuk</div>
            <div class="kpi-icon-wrap c-cyan">
                <svg viewBox="0 0 24 24"><path d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
            </div>
        </div>
        <div class="kpi-value" id="kStockIn">—</div>
        <div class="kpi-badge b-cyan" id="kStockInCost">Rp 0</div>
    </div>

    <div class="kpi c-indigo">
        <div class="kpi-top">
            <div class="kpi-label">Stok Keluar</div>
            <div class="kpi-icon-wrap c-indigo">
                <svg viewBox="0 0 24 24"><path d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
            </div>
        </div>
        <div class="kpi-value" id="kStockOut">—</div>
        <div class="kpi-badge b-primary" id="kStockOutCost">Rp 0</div>
    </div>

    <div class="kpi c-amber">
        <div class="kpi-top">
            <div class="kpi-label">Total Omzet</div>
            <div class="kpi-icon-wrap c-amber">
                <svg viewBox="0 0 24 24"><path d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
        </div>
        <div class="kpi-value sm" id="kRevenue">—</div>
        <div class="kpi-badge b-warning" id="kTrx">0 transaksi</div>
    </div>

    <div class="kpi c-green">
        <div class="kpi-top">
            <div class="kpi-label">Laba Kotor</div>
            <div class="kpi-icon-wrap c-green">
                <svg viewBox="0 0 24 24"><path d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            </div>
        </div>
        <div class="kpi-value sm" id="kProfit">—</div>
        <div class="kpi-badge b-success">Gross Profit</div>
    </div>
</div>

<!-- Charts Row -->
<div class="g2 mb-4">
    <div class="card">
        <div class="card-header">
            <span class="card-title">💰 Grafik Omzet</span>
            <span class="fs-xs text-muted" id="chartPeriodLabel">Harian</span>
        </div>
        <div class="card-body">
            <div class="chart-wrap"><canvas id="revenueChart"></canvas></div>
        </div>
    </div>

    <div class="card">
        <div class="card-header">
            <span class="card-title">📦 Stok Masuk vs Keluar</span>
        </div>
        <div class="card-body">
            <div class="chart-wrap"><canvas id="stockChart"></canvas></div>
        </div>
    </div>
</div>

<!-- Timeline -->
<div class="card">
    <div class="card-header">
        <span class="card-title">⏱️ Timeline Pergerakan Stok</span>
        <div class="d-flex ai-c gap-2">
            <span class="badge b-in">▲ Masuk</span>
            <span class="badge b-out">▼ Keluar</span>
        </div>
    </div>
    <div style="padding:1rem 1.25rem">
        <div id="timelineLoading" class="empty-state" style="padding:2rem">
            <div style="display:inline-flex;width:32px;height:32px;border:3px solid var(--border);border-top-color:var(--primary);border-radius:50%;animation:spin .7s linear infinite;margin-bottom:.75rem"></div>
            <div class="empty-title">Memuat data…</div>
        </div>
        <div id="timelineEmpty" class="empty-state" style="display:none;padding:2rem">
            <div class="empty-icon">📋</div>
            <div class="empty-title">Tidak ada data pada periode ini</div>
        </div>
        <div id="timelineList" style="display:none"></div>
    </div>
    <div style="padding:.625rem 1.25rem;border-top:1px solid var(--border);background:#F8FAFC;display:flex;justify-content:space-between;align-items:center">
        <span class="fs-xs text-muted">Menampilkan maks. 50 entri terbaru</span>
        <span class="fs-xs text-muted" id="timelineCount">0 entri</span>
    </div>
</div>

@push('head')
<style>
@keyframes spin{to{transform:rotate(360deg)}}
</style>
@endpush
@endsection

@push('scripts')
<script>
Chart.defaults.font.family="'Inter',sans-serif";
Chart.defaults.color='#64748B';

let currentPeriod='daily';
let revenueChart=null;
let stockChart=null;

const periodLabels={daily:'Harian',weekly:'Mingguan',monthly:'Bulanan',yearly:'Tahunan'};

function setPeriod(p,btn){
    currentPeriod=p;
    document.querySelectorAll('.period-tab').forEach(t=>t.classList.remove('on'));
    btn.classList.add('on');
    document.getElementById('chartPeriodLabel').textContent=periodLabels[p];
    loadData(p);
}

async function loadData(period){
    document.getElementById('timelineLoading').style.display='block';
    document.getElementById('timelineEmpty').style.display='none';
    document.getElementById('timelineList').style.display='none';

    // KPI skeleton
    ['kStockIn','kStockOut','kRevenue','kProfit'].forEach(id=>document.getElementById(id).textContent='…');

    try{
        const res=await fetch(`/reports/data?period=${period}`);
        const data=await res.json();
        const s=data.summary;

        // Update KPI cards
        document.getElementById('kStockIn').textContent=s.stock_in.qty+' unit';
        document.getElementById('kStockInCost').textContent='Modal: '+fmt(s.stock_in.cost);
        document.getElementById('kStockOut').textContent=s.stock_out.qty+' unit';
        document.getElementById('kStockOutCost').textContent='Modal terjual: '+fmt(s.stock_out.cost);
        document.getElementById('kRevenue').textContent=fmt(s.revenue);
        document.getElementById('kTrx').textContent=s.total_trx+' transaksi';
        document.getElementById('kProfit').textContent=fmt(s.gross_profit);

        // Update charts
        const labels=data.chart.map(d=>d.label);
        const revenues=data.chart.map(d=>d.revenue);
        const ins=data.chart.map(d=>d.in);
        const outs=data.chart.map(d=>d.out);

        if(revenueChart) revenueChart.destroy();
        revenueChart=new Chart(document.getElementById('revenueChart'),{
            type:'line',
            data:{
                labels,
                datasets:[{
                    label:'Omzet',
                    data:revenues,
                    borderColor:'rgba(79,70,229,1)',
                    backgroundColor:'rgba(79,70,229,0.08)',
                    borderWidth:2.5,
                    fill:true,
                    tension:.4,
                    pointRadius:4,
                    pointBackgroundColor:'rgba(79,70,229,1)',
                    pointBorderColor:'#fff',
                    pointBorderWidth:2,
                }]
            },
            options:{
                responsive:true,maintainAspectRatio:false,
                plugins:{legend:{display:false},tooltip:{callbacks:{label:c=>' '+fmt(c.raw)}}},
                scales:{
                    y:{beginAtZero:true,grid:{color:'rgba(0,0,0,0.04)'},ticks:{callback:v=>'Rp '+new Intl.NumberFormat('id-ID').format(v),font:{size:10}}},
                    x:{grid:{display:false},ticks:{font:{size:10}}}
                }
            }
        });

        if(stockChart) stockChart.destroy();
        stockChart=new Chart(document.getElementById('stockChart'),{
            type:'bar',
            data:{
                labels,
                datasets:[
                    {label:'Stok Masuk',data:ins,backgroundColor:'rgba(16,185,129,.7)',borderRadius:4,borderSkipped:false},
                    {label:'Stok Keluar',data:outs,backgroundColor:'rgba(239,68,68,.7)',borderRadius:4,borderSkipped:false},
                ]
            },
            options:{
                responsive:true,maintainAspectRatio:false,
                plugins:{legend:{display:true,position:'top',labels:{boxWidth:12,font:{size:11}}}},
                scales:{
                    y:{beginAtZero:true,grid:{color:'rgba(0,0,0,0.04)'},stacked:false,ticks:{font:{size:10}}},
                    x:{grid:{display:false},ticks:{font:{size:10}}}
                }
            }
        });

        // Timeline
        renderTimeline(data.timeline);

    } catch(e){
        console.error(e);
        document.getElementById('timelineLoading').style.display='none';
        document.getElementById('timelineEmpty').style.display='block';
    }
}

function renderTimeline(items){
    document.getElementById('timelineLoading').style.display='none';
    document.getElementById('timelineCount').textContent=items.length+' entri';

    if(!items.length){
        document.getElementById('timelineEmpty').style.display='block';
        return;
    }

    const list=document.getElementById('timelineList');
    list.style.display='block';
    list.innerHTML=items.map(item=>{
        const isIn=item.type==='in';
        const typeLabel=isIn?'▲ MASUK':'▼ KELUAR';
        const refLabel=({sale:'Penjualan',supplier_restock:'Restock Supplier',initial_stock:'Stok Awal',adjustment:'Penyesuaian'})[item.reference_type]||item.reference_type||'—';

        return `
        <div class="timeline-item">
            <div class="tl-dot ${item.type}">${isIn?'↑':'↓'}</div>
            <div class="tl-body">
                <div class="tl-title">${item.product_name}</div>
                <div class="tl-meta">
                    <span class="badge ${isIn?'b-in':'b-out'}" style="font-size:.6rem">${typeLabel}</span>
                    &nbsp;${refLabel} · <span style="font-family:monospace">${item.product_sku}</span>
                </div>
                ${item.notes?`<div class="tl-meta" style="margin-top:.25rem;font-style:italic">"${item.notes}"</div>`:''}
            </div>
            <div class="tl-right">
                <div class="tl-qty ${item.type}">${isIn?'+':'-'}${item.quantity} unit</div>
                <div class="tl-cost">${fmt(item.total_cost)}</div>
                <div class="tl-cost" style="margin-top:.125rem">${item.date}</div>
            </div>
        </div>`;
    }).join('');
}

// Init
loadData('daily');
</script>
@endpush
