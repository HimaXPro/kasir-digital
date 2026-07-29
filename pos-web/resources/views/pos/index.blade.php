@extends('layouts.app')
@section('title', 'Kasir')
@section('breadcrumb', 'Kasir')

@section('content')
<div class="page-header">
    <div class="page-header-row">
        <div>
            <h1 class="page-title">🛒 Kasir</h1>
            <p class="page-sub">Klik produk untuk menambahkan ke keranjang</p>
        </div>
    </div>
</div>

<div class="pos-layout">
    <!-- ── Product Panel ── -->
    <div class="pos-products">
        <div class="pos-top">
            <div class="input-icon" style="flex:1">
                <svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
                <input id="searchProd" type="text" class="form-control" placeholder="Cari nama produk atau SKU…" autocomplete="off">
            </div>
        </div>
        <div class="cat-tabs">
            <button class="cat-tab on" onclick="filterCat('all',this)">Semua</button>
            @foreach($categories as $cat)
            <button class="cat-tab" onclick="filterCat('{{ $cat->id }}',this)">{{ $cat->name }}</button>
            @endforeach
        </div>
        <div class="prod-grid" id="prodGrid">
            @php
                $emojis=['🍜','🥤','☕','🍕','🍱','🧃','🍗','🥗','🍰','🍔','🥐','🍩'];
                $colors=['#EEF2FF','#ECFEFF','#ECFDF5','#FFFBEB','#FEF2F2','#F5F3FF'];
            @endphp
            @foreach($products as $product)
            @php $idx=$product->id%count($emojis); $cidx=$product->id%count($colors); @endphp
            <div class="prod-card {{ $product->stock <= 0 ? 'sold-out' : '' }}"
                 data-id="{{ $product->id }}"
                 data-name="{{ addslashes($product->name) }}"
                 data-price="{{ $product->selling_price }}"
                 data-stock="{{ $product->stock }}"
                 data-cat="{{ $product->category_id ?? 0 }}"
                 onclick="{{ $product->stock > 0 ? 'addToCart(this)' : '' }}">
                <div class="prod-emoji" style="background:{{ $colors[$cidx] }}">{{ $emojis[$idx] }}</div>
                <div class="prod-name">{{ $product->name }}</div>
                <div class="prod-price">Rp {{ number_format($product->selling_price, 0, ',', '.') }}</div>
                <div class="prod-stock">
                    @if($product->stock > 10)
                        <span style="color:var(--success)">● Stok: {{ $product->stock }}</span>
                    @elseif($product->stock > 0)
                        <span style="color:var(--warning)">● Stok: {{ $product->stock }}</span>
                    @else
                        <span style="color:var(--danger)">● Habis</span>
                    @endif
                </div>
                @if($product->stock <= 0)
                <div class="sold-out-badge"><span class="sold-out-text">HABIS</span></div>
                @endif
            </div>
            @endforeach
            <div id="noProduct" style="display:none;grid-column:1/-1" class="empty-state">
                <div class="empty-icon">🔍</div>
                <div class="empty-title">Produk tidak ditemukan</div>
            </div>
        </div>
    </div>

    <!-- ── Cart Panel ── -->
    <div class="pos-cart">
        <div class="cart-hd">
            <span class="cart-hd-title">
                <svg style="width:16px;height:16px;stroke:#fff;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                Keranjang
            </span>
            <div class="d-flex ai-c gap-2">
                <span class="cart-count" id="cartCount">0 item</span>
                <button onclick="clearCart()" style="background:rgba(255,255,255,.15);border:none;border-radius:var(--radius-sm);padding:.2rem .5rem;cursor:pointer;color:#fff;font-size:.6875rem;font-family:inherit;display:none" id="clearBtn">Hapus</button>
            </div>
        </div>

        <div id="cartItems" class="cart-items">
            <div class="cart-empty" id="cartEmpty" style="display:flex;flex-direction:column">
                <div style="font-size:2.25rem;margin-bottom:.5rem">🛒</div>
                <div style="font-weight:700;color:var(--text-secondary)">Keranjang Kosong</div>
                <div class="fs-sm text-muted mt-1">Klik produk untuk mulai</div>
            </div>
        </div>

        <div class="cart-ft">
            <div id="cartSummary" style="display:none">
                <div class="sum-row"><span>Subtotal</span><span id="subtotalTxt">Rp 0</span></div>
                <div class="sum-row">
                    <span>Diskon (Rp)</span>
                    <input type="number" id="discountInput" style="width:90px;padding:.25rem .5rem;border:1px solid var(--border);border-radius:var(--radius-sm);font-size:.8125rem;font-family:inherit;text-align:right;background:#fff" value="0" min="0" oninput="updateCart()">
                </div>
                <div class="sum-total">
                    <span class="sum-total-lbl">TOTAL</span>
                    <span class="sum-total-val" id="totalTxt">Rp 0</span>
                </div>
            </div>
            <button id="checkoutBtn" class="btn btn-primary btn-xl w-full mt-3" onclick="openPayModal()" disabled style="opacity:.5">
                💳 Proses Pembayaran
            </button>
        </div>
    </div>
</div>

<!-- ── Payment Modal ── -->
<div class="modal-ov" id="payModal">
    <div class="modal">
        <div class="modal-header">
            <span class="modal-title">💳 Konfirmasi Pembayaran</span>
            <button class="btn btn-ghost btn-icon btn-sm" onclick="closeModal('payModal')" style="font-size:1.125rem">✕</button>
        </div>
        <div class="modal-body">
            <div style="background:var(--primary-light);border-radius:var(--radius-sm);padding:.875rem 1rem;margin-bottom:1rem;display:flex;justify-content:space-between;align-items:center">
                <span class="fs-sm text-secondary-c fw-5">Total Pembayaran</span>
                <span id="modalTotal" style="font-size:1.25rem;font-weight:900;color:var(--primary)">Rp 0</span>
            </div>

            <div class="form-group">
                <label class="form-label">Metode Pembayaran</label>
                <div class="pay-method-grid">
                    <button class="pay-method-btn on" onclick="selMethod('cash',this)">💵 Cash</button>
                    <button class="pay-method-btn" onclick="selMethod('qris',this)">📱 QRIS</button>
                </div>
            </div>

            <div class="form-group" id="cashGroup">
                <label class="form-label">Uang Bayar (Rp)<span class="req">*</span></label>
                <input type="number" id="payAmount" class="form-control" placeholder="Masukkan nominal uang…" oninput="calcChange()" style="font-size:1rem;font-weight:700">
                <!-- Quick amount buttons -->
                <div class="d-flex gap-2 flex-wrap mt-2" id="quickAmounts"></div>
            </div>

            <div class="change-box mt-3" id="changeBox" style="display:none">
                <div class="change-lbl">Kembalian</div>
                <div class="change-val" id="changeTxt">Rp 0</div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-outline" onclick="closeModal('payModal')">Batal</button>
            <button id="processBtn" class="btn btn-success btn-lg" onclick="processTrx()">✓ Bayar Sekarang</button>
        </div>
    </div>
</div>

<!-- ── Success / Invoice Modal ── -->
<div class="modal-ov" id="successModal">
    <div class="modal" style="max-width:420px">
        <div class="modal-header" style="background:linear-gradient(135deg,var(--success),#059669)">
            <span class="modal-title" style="color:#fff">✅ Transaksi Berhasil!</span>
        </div>
        <div class="modal-body">
            <!-- Invoice Preview -->
            <div id="invoicePreview" style="font-family:'Courier New',monospace;background:#FAFAFA;border:1px dashed var(--border);border-radius:var(--radius-sm);padding:1rem;font-size:.8125rem;line-height:1.7">
                <!-- filled by JS -->
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-outline" onclick="resetPOS()">🔄 Transaksi Baru</button>
            <button class="btn btn-warning" onclick="printReceipt()" style="color:#fff">🖨️ Cetak Nota</button>
        </div>
    </div>
</div>

@push('head')
<style>
/* ── Receipt Print Styles ───────────────────────────────────────── */
@media print {
    .sidebar,.main-wrap .topbar,.bottom-nav,.modal-footer,
    .modal-header button,.page-content>*:not(#printArea){display:none!important}
    #printArea{display:block!important;position:fixed;inset:0;z-index:9999;background:#fff}
    @page{margin:0}
}

/* ── POS mobile tab layout ──────────────────────────────────────── */
@media (max-width: 768px){
    .pos-panel-tabs{display:flex;background:#F1F5F9;border-radius:var(--radius-sm);padding:.25rem;gap:.25rem;margin-bottom:.75rem}
    .pos-panel-tab{flex:1;padding:.4375rem .5rem;border-radius:calc(var(--radius-sm) - 2px);font-size:.8125rem;font-weight:600;cursor:pointer;transition:var(--tr);color:var(--text-secondary);border:none;background:transparent;font-family:inherit;text-align:center}
    .pos-panel-tab.on{background:#fff;color:var(--text-primary);box-shadow:0 1px 3px rgba(0,0,0,.1)}
    .pos-products{display:none}.pos-products.show{display:flex}
    .pos-cart{display:none}.pos-cart.show{display:flex}
}
</style>
@endpush
@endsection

@push('scripts')
<script>
let cart={};
let payMethod='cash';
let lastTrxData={};

/* ── Mobile tab switching ───────────────────────────────────────────── */
function initMobileTabs(){
    if(window.innerWidth>768){
        document.getElementById('posProducts').classList.add('show');
        document.getElementById('posCart').classList.add('show');
        return;
    }
    document.getElementById('posProducts').classList.add('show');
}
window.addEventListener('resize',()=>{
    if(window.innerWidth>768){
        document.getElementById('posProducts').classList.add('show');
        document.getElementById('posCart').classList.add('show');
    }
});

function switchPosTab(tab){
    document.querySelectorAll('.pos-panel-tab').forEach(t=>t.classList.remove('on'));
    event.target.classList.add('on');
    if(tab==='products'){
        document.getElementById('posProducts').classList.add('show');
        document.getElementById('posProducts').classList.remove('hide');
        document.getElementById('posCart').classList.remove('show');
    } else {
        document.getElementById('posCart').classList.add('show');
        document.getElementById('posProducts').classList.remove('show');
    }
}

/* ── Cart Logic ─────────────────────────────────────────────────────── */
function addToCart(el){
    const id=el.dataset.id, name=el.dataset.name;
    const price=parseFloat(el.dataset.price), stock=parseInt(el.dataset.stock);
    if(!cart[id]) cart[id]={id,name,price,stock,qty:0};
    if(cart[id].qty>=stock){showToast('Stok tidak mencukupi!','error');return;}
    cart[id].qty++;
    el.style.transform='scale(.93)';
    setTimeout(()=>el.style.transform='',150);
    renderCart();
    // On mobile: switch to cart tab after adding
    if(window.innerWidth<=768){
        document.querySelectorAll('.pos-panel-tab')[1]?.click?.();
    }
}
function removeItem(id){delete cart[id];renderCart();}
function changeQty(id,d){
    if(!cart[id])return;
    cart[id].qty+=d;
    if(cart[id].qty<=0){delete cart[id];}
    else if(cart[id].qty>cart[id].stock){cart[id].qty=cart[id].stock;showToast('Stok maks tercapai!','error');}
    renderCart();
}
function clearCart(){
    if(!confirm('Kosongkan keranjang?'))return;
    cart={};renderCart();
}

function renderCart(){
    const items=Object.values(cart);
    const total=items.reduce((s,i)=>s+i.qty,0);
    document.getElementById('cartCount').textContent=total+' item';
    document.getElementById('clearBtn').style.display=total?'block':'none';

    const ci=document.getElementById('cartItems');
    [...ci.children].forEach(c=>{if(c.id!=='cartEmpty')c.remove();});

    if(!items.length){
        document.getElementById('cartEmpty').style.display='flex';
        document.getElementById('cartSummary').style.display='none';
        const btn=document.getElementById('checkoutBtn');btn.disabled=true;btn.style.opacity='.5';
        return;
    }
    document.getElementById('cartEmpty').style.display='none';
    document.getElementById('cartSummary').style.display='block';
    const btn=document.getElementById('checkoutBtn');btn.disabled=false;btn.style.opacity='1';

    items.forEach(item=>{
        const el=document.createElement('div');
        el.className='cart-item';
        el.innerHTML=`
            <div class="ci-info">
                <div class="ci-name">${item.name}</div>
                <div class="ci-price">${fmt(item.price)} × ${item.qty}</div>
                <div class="qty-ctrl">
                    <button class="qty-btn" onclick="changeQty('${item.id}',-1)">−</button>
                    <span class="qty-n">${item.qty}</span>
                    <button class="qty-btn" onclick="changeQty('${item.id}',1)">+</button>
                </div>
            </div>
            <div style="display:flex;flex-direction:column;align-items:flex-end;justify-content:space-between;flex-shrink:0">
                <button onclick="removeItem('${item.id}')" style="background:none;border:none;cursor:pointer;color:var(--danger);font-size:1.25rem;line-height:1;padding:.125rem">×</button>
                <span style="font-weight:800;font-size:.875rem;color:var(--text-primary);margin-top:.5rem">${fmt(item.price*item.qty)}</span>
            </div>`;
        ci.appendChild(el);
    });
    updateCart();
}

function updateCart(){
    const items=Object.values(cart);
    const sub=items.reduce((s,i)=>s+i.price*i.qty,0);
    const disc=parseFloat(document.getElementById('discountInput').value)||0;
    const total=Math.max(0,sub-disc);
    document.getElementById('subtotalTxt').textContent=fmt(sub);
    document.getElementById('totalTxt').textContent=fmt(total);
}
function getSubtotal(){return Object.values(cart).reduce((s,i)=>s+i.price*i.qty,0);}
function getTotal(){
    const disc=parseFloat(document.getElementById('discountInput').value)||0;
    return Math.max(0,getSubtotal()-disc);
}

/* ── Search & filter ────────────────────────────────────────────────── */
document.getElementById('searchProd').addEventListener('input',function(){
    const q=this.value.toLowerCase();
    let visible=0;
    document.querySelectorAll('.prod-card').forEach(c=>{
        const match=c.dataset.name.toLowerCase().includes(q);
        c.style.display=match?'':'none';
        if(match)visible++;
    });
    document.getElementById('noProduct').style.display=visible?'none':'block';
});
function filterCat(catId,btn){
    document.querySelectorAll('.cat-tab').forEach(t=>t.classList.remove('on'));
    btn.classList.add('on');
    let visible=0;
    document.querySelectorAll('.prod-card').forEach(c=>{
        const match=catId==='all'||c.dataset.cat===catId;
        c.style.display=match?'':'none';
        if(match)visible++;
    });
    document.getElementById('noProduct').style.display=visible?'none':'block';
}

/* ── Payment modal ──────────────────────────────────────────────────── */
function openPayModal(){
    if(!Object.keys(cart).length)return;
    const total=getTotal();
    document.getElementById('modalTotal').textContent=fmt(total);
    document.getElementById('payAmount').value='';
    document.getElementById('changeBox').style.display='none';
    document.querySelectorAll('.pay-method-btn').forEach((b,i)=>b.classList.toggle('on',i===0));
    payMethod='cash';
    document.getElementById('cashGroup').style.display='block';
    // Quick amount buttons
    const qa=document.getElementById('quickAmounts');
    qa.innerHTML='';
    [total,Math.ceil(total/5000)*5000,Math.ceil(total/10000)*10000,Math.ceil(total/50000)*50000,Math.ceil(total/100000)*100000].filter((v,i,a)=>a.indexOf(v)===i&&v>=total).slice(0,4).forEach(amt=>{
        const b=document.createElement('button');
        b.className='btn btn-outline btn-sm';
        b.textContent=fmt(amt);
        b.onclick=()=>{document.getElementById('payAmount').value=amt;calcChange();};
        qa.appendChild(b);
    });
    openModal('payModal');
}
function selMethod(m,btn){
    payMethod=m;
    document.querySelectorAll('.pay-method-btn').forEach(b=>b.classList.remove('on'));
    btn.classList.add('on');
    document.getElementById('cashGroup').style.display=m==='cash'?'block':'none';
    if(m!=='cash')document.getElementById('changeBox').style.display='none';
}
function calcChange(){
    const total=getTotal();
    const pay=parseFloat(document.getElementById('payAmount').value)||0;
    const change=pay-total;
    const box=document.getElementById('changeBox');
    if(pay>0&&change>=0){
        box.style.display='block';
        document.getElementById('changeTxt').textContent=fmt(change);
    } else {
        box.style.display='none';
    }
}

/* ── Process transaction ─────────────────────────────────────────────── */
async function processTrx(){
    const total=getTotal();
    let payAmt=payMethod==='cash'?parseFloat(document.getElementById('payAmount').value)||0:total;
    if(payMethod==='cash'&&payAmt<total){showToast('Uang pembayaran kurang!','error');return;}
    const btn=document.getElementById('processBtn');
    btn.disabled=true;btn.textContent='⏳ Memproses…';

    try{
        const res=await fetch('/pos/transactions',{
            method:'POST',
            headers:{
                'Content-Type':'application/json',
                'Accept':'application/json',
                'X-CSRF-TOKEN':document.querySelector('meta[name="csrf-token"]').content
            },
            body:JSON.stringify({
                items:Object.values(cart).map(i=>({product_id:parseInt(i.id),quantity:i.qty})),
                pay_amount:payAmt,
                payment_method:payMethod,
                discount_amount:parseFloat(document.getElementById('discountInput').value)||0,
            })
        });
        const data=await res.json();
        if(data.success){
            lastTrxData={...data.data,payAmt,payMethod,change:payAmt-total,items:Object.values(cart),subtotal:getSubtotal(),discount:parseFloat(document.getElementById('discountInput').value)||0,total};
            closeModal('payModal');
            buildInvoicePreview(lastTrxData);
            openModal('successModal');
        } else {
            showToast(data.message||'Transaksi gagal!','error');
        }
    } catch(e){showToast('Terjadi kesalahan. Coba lagi.','error');}
    finally{btn.disabled=false;btn.textContent='✓ Bayar Sekarang';}
}

/* ── Build invoice preview (inline) ─────────────────────────────────── */
function buildInvoicePreview(d){
    const now=new Date();
    const dateWIB=now.toLocaleString('id-ID',{timeZone:'Asia/Jakarta',day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit',second:'2-digit'}).replace(',','');
    const sep='─'.repeat(32);
    const halfSep='─'.repeat(32);

    let itemsHtml=d.items.map(i=>`
        <div style="margin:.25rem 0">
            <div>${i.name}</div>
            <div style="display:flex;justify-content:space-between;padding-left:1rem">
                <span>${i.qty} × ${fmtNum(i.price)}</span>
                <span>${fmtNum(i.price*i.qty)}</span>
            </div>
        </div>`).join('');

    document.getElementById('invoicePreview').innerHTML=`
        <div style="text-align:center;margin-bottom:.5rem">
            <div style="font-size:1rem;font-weight:800;letter-spacing:.05em">KASIR DIGITAL</div>
            <div style="font-size:.7rem;color:var(--text-muted)">Point of Sale System</div>
        </div>
        <div style="border-top:1px dashed #ccc;margin:.5rem 0"></div>
        <div style="display:flex;justify-content:space-between"><span>Invoice</span><strong>${d.invoice_number}</strong></div>
        <div style="display:flex;justify-content:space-between"><span>Waktu</span><span>${dateWIB} WIB</span></div>
        <div style="display:flex;justify-content:space-between"><span>Kasir</span><span>Admin</span></div>
        <div style="border-top:1px dashed #ccc;margin:.5rem 0"></div>
        ${itemsHtml}
        <div style="border-top:1px dashed #ccc;margin:.5rem 0"></div>
        <div style="display:flex;justify-content:space-between"><span>Subtotal</span><span>${fmt(d.subtotal)}</span></div>
        ${d.discount>0?`<div style="display:flex;justify-content:space-between"><span>Diskon</span><span>-${fmt(d.discount)}</span></div>`:''}
        <div style="display:flex;justify-content:space-between;font-weight:900;font-size:1rem;margin:.25rem 0"><span>TOTAL</span><span>${fmt(d.total)}</span></div>
        <div style="border-top:1px dashed #ccc;margin:.5rem 0"></div>
        <div style="display:flex;justify-content:space-between"><span>Bayar (${d.payMethod.toUpperCase()})</span><span>${fmt(d.payAmt)}</span></div>
        <div style="display:flex;justify-content:space-between;color:var(--success);font-weight:700"><span>Kembalian</span><span>${fmt(Math.max(0,d.change))}</span></div>
        <div style="border-top:1px dashed #ccc;margin:.5rem 0"></div>
        <div style="text-align:center;font-size:.75rem;color:var(--text-muted)">
            <div>Terima kasih atas kunjungan Anda!</div>
            <div>Barang yang sudah dibeli</div>
            <div>tidak dapat dikembalikan</div>
        </div>`;
}

/* ── Print receipt ───────────────────────────────────────────────────── */
function printReceipt(){
    const d=lastTrxData;
    if(!d.invoice_number)return;
    const now=new Date();
    const dateWIB=now.toLocaleString('id-ID',{timeZone:'Asia/Jakarta',day:'2-digit',month:'long',year:'numeric',hour:'2-digit',minute:'2-digit'});

    const itemsHtml=d.items.map(i=>`
        <tr><td colspan="3">${i.name}</td></tr>
        <tr>
            <td style="padding-left:1em">${i.qty} × Rp ${fmtNum(i.price)}</td>
            <td></td>
            <td style="text-align:right">Rp ${fmtNum(i.price*i.qty)}</td>
        </tr>`).join('');

    const html=`<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Nota — ${d.invoice_number}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',Courier,monospace;font-size:12px;color:#000;width:100%;max-width:80mm;margin:0 auto;padding:4mm}
.center{text-align:center}.bold{font-weight:bold}.big{font-size:15px}
.sep{border:none;border-top:1px dashed #000;margin:6px 0}
table{width:100%;border-collapse:collapse}
td{padding:1px 0;vertical-align:top}
.total-row td{font-weight:bold;font-size:14px;padding-top:4px;padding-bottom:4px}
.footer{text-align:center;font-size:10px;margin-top:8px}
@media print{
    @page{margin:0}
    body{width:100%}
}
</style>
</head>
<body>
<div class="center">
    <div class="bold big">KASIR DIGITAL</div>
    <div>Point of Sale System</div>
    <div style="font-size:10px;margin-top:2px">☎ — | 📍 —</div>
</div>
<hr class="sep">
<table>
    <tr><td class="bold">Invoice</td><td style="text-align:right">${d.invoice_number}</td></tr>
    <tr><td class="bold">Tanggal</td><td style="text-align:right">${dateWIB} WIB</td></tr>
    <tr><td class="bold">Kasir</td><td style="text-align:right">Admin</td></tr>
    <tr><td class="bold">Metode</td><td style="text-align:right">${d.payMethod.toUpperCase()}</td></tr>
</table>
<hr class="sep">
<table>${itemsHtml}</table>
<hr class="sep">
<table>
    <tr><td>Subtotal</td><td style="text-align:right">Rp ${fmtNum(d.subtotal)}</td></tr>
    ${d.discount>0?`<tr><td>Diskon</td><td style="text-align:right">-Rp ${fmtNum(d.discount)}</td></tr>`:''}
</table>
<hr class="sep">
<table>
    <tr class="total-row"><td>TOTAL</td><td style="text-align:right">Rp ${fmtNum(d.total)}</td></tr>
    <tr><td>Bayar</td><td style="text-align:right">Rp ${fmtNum(d.payAmt)}</td></tr>
    <tr class="bold"><td>Kembalian</td><td style="text-align:right">Rp ${fmtNum(Math.max(0,d.change))}</td></tr>
</table>
<hr class="sep">
<div class="footer">
    <p>★ Terima kasih atas kunjungan Anda! ★</p>
    <p>Barang yang sudah dibeli tidak dapat dikembalikan</p>
    <p style="margin-top:4px">~~~ Selamat Berbelanja ~~~</p>
</div>
<br><br>
</body>
</html>`;

    const win=window.open('','_blank','width=420,height=700,scrollbars=yes');
    if(!win){showToast('Popup diblokir. Izinkan popup di browser Anda.','error');return;}
    win.document.write(html);
    win.document.close();
    win.focus();
    setTimeout(()=>{win.print();},400);
}

/* ── Reset ────────────────────────────────────────────────────────────── */
function resetPOS(){
    cart={};
    document.getElementById('discountInput').value=0;
    renderCart();
    closeModal('successModal');
    location.reload();
}

/* ── Init mobile layout ──────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded',()=>{
    if(window.innerWidth<=768){
        // Insert mobile tab switcher before the pos layout
        const posLayout=document.querySelector('.pos-layout');
        const tabHtml=`<div class="pos-panel-tabs" style="display:flex;background:#F1F5F9;border-radius:var(--radius-sm);padding:.25rem;gap:.25rem;margin-bottom:.75rem">
            <button class="pos-panel-tab on" onclick="switchTab('products',this)">📦 Produk</button>
            <button class="pos-panel-tab" onclick="switchTab('cart',this)">🛒 Keranjang <span id="cartBadge" style="background:var(--primary);color:#fff;border-radius:100px;padding:.1rem .4rem;font-size:.625rem;font-weight:800;display:none">0</span></button>
        </div>`;
        posLayout.insertAdjacentHTML('beforebegin',tabHtml);
        // Apply IDs for tab targeting
        document.querySelector('.pos-products').id='posProducts';
        document.querySelector('.pos-cart').id='posCart';
        document.querySelector('.pos-products').style.display='flex';
        document.querySelector('.pos-cart').style.display='none';
    } else {
        document.querySelector('.pos-products').style.display='flex';
        document.querySelector('.pos-cart').style.display='flex';
    }
});

function switchTab(tab,btn){
    document.querySelectorAll('.pos-panel-tab').forEach(t=>t.classList.remove('on'));
    btn.classList.add('on');
    if(tab==='products'){
        document.querySelector('.pos-products').style.display='flex';
        document.querySelector('.pos-cart').style.display='none';
    } else {
        document.querySelector('.pos-cart').style.display='flex';
        document.querySelector('.pos-products').style.display='none';
    }
}
</script>
@endpush
