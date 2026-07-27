@extends('layouts.app')
@section('title', 'Kasir POS')
@section('breadcrumb', 'Kasir POS')

@section('content')
<div class="d-flex ai-c jb mb-3" style="margin-top:-.25rem">
    <div>
        <h1 class="page-title">🛒 Kasir POS</h1>
        <p class="page-sub">Klik produk untuk menambahkan ke keranjang. Tahan Ctrl+F untuk cari cepat.</p>
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
                 data-name="{{ $product->name }}"
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
                <svg style="width:18px;height:18px;stroke:#fff;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                Keranjang
            </span>
            <span class="cart-count" id="cartCount">0 item</span>
        </div>

        <div id="cartItems" class="cart-items">
            <div class="cart-empty" id="cartEmpty">
                <div style="font-size:2.5rem;margin-bottom:.5rem">🛒</div>
                <div style="font-weight:700;color:var(--text-secondary)">Keranjang Kosong</div>
                <div class="fs-sm text-muted mt-1">Klik produk untuk mulai</div>
            </div>
        </div>

        <div class="cart-ft">
            <div id="cartSummary" style="display:none">
                <div class="sum-row"><span>Subtotal</span><span id="subtotalTxt">Rp 0</span></div>
                <div class="sum-row">
                    <span>Diskon</span>
                    <div class="d-flex ai-c gap-2">
                        <input type="number" id="discountInput" style="width:90px;padding:.25rem .5rem;border:1px solid var(--border);border-radius:var(--radius-sm);font-size:.8125rem;font-family:inherit;text-align:right" value="0" min="0" oninput="updateCart()">
                    </div>
                </div>
                <div class="sum-total">
                    <span class="sum-total-lbl">TOTAL</span>
                    <span class="sum-total-val" id="totalTxt">Rp 0</span>
                </div>
            </div>

            <button id="checkoutBtn" class="btn btn-primary btn-xl w-full mt-3" onclick="openModal('payModal')" disabled style="justify-content:center;opacity:.5">
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
            <button class="btn btn-ghost btn-icon" onclick="closeModal('payModal')" style="font-size:1.125rem">✕</button>
        </div>
        <div class="modal-body">
            <div style="background:var(--primary-light);border-radius:var(--radius-sm);padding:.875rem 1rem;margin-bottom:1.125rem;display:flex;justify-content:space-between;align-items:center">
                <span class="fs-sm text-secondary-c fw-5">Total yang harus dibayar</span>
                <span id="modalTotal" style="font-size:1.375rem;font-weight:900;color:var(--primary)">Rp 0</span>
            </div>

            <div class="form-group">
                <label class="form-label">Metode Pembayaran</label>
                <div class="pay-method-grid">
                    <button class="pay-method-btn on" onclick="selMethod('cash',this)">💵 Cash</button>
                    <button class="pay-method-btn" onclick="selMethod('qris',this)">📱 QRIS</button>
                    <button class="pay-method-btn" onclick="selMethod('transfer',this)">🏦 Transfer</button>
                    <button class="pay-method-btn" onclick="selMethod('debit',this)">💳 Debit</button>
                </div>
            </div>

            <div class="form-group" id="cashGroup">
                <label class="form-label">Uang Bayar (Rp)<span class="req">*</span></label>
                <input type="number" id="payAmount" class="form-control" placeholder="Masukkan nominal uang…" oninput="calcChange()">
            </div>

            <div class="change-box mt-3" id="changeBox" style="display:none">
                <div class="change-lbl">Kembalian</div>
                <div class="change-val" id="changeTxt">Rp 0</div>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn btn-outline" onclick="closeModal('payModal')">Batal</button>
            <button id="processBtn" class="btn btn-success btn-lg" onclick="processTrx()">✓ Konfirmasi Bayar</button>
        </div>
    </div>
</div>

<!-- ── Success Modal ── -->
<div class="modal-ov" id="successModal">
    <div class="modal modal-sm" style="text-align:center">
        <div class="modal-body" style="padding:2rem 1.5rem">
            <div style="font-size:3.5rem;margin-bottom:.75rem">✅</div>
            <h3 style="font-size:1.25rem;font-weight:800;color:var(--text-primary);margin-bottom:.375rem">Transaksi Berhasil!</h3>
            <p class="text-muted fs-sm mb-1">No. Invoice</p>
            <p style="font-size:.9375rem;font-weight:700;color:var(--primary);margin-bottom:.875rem" id="invNumber">—</p>
            <div class="change-box mb-4">
                <div class="change-lbl">Kembalian</div>
                <div class="change-val" id="finalChange">Rp 0</div>
            </div>
            <button class="btn btn-primary btn-xl w-full" onclick="resetPOS()" style="justify-content:center">🔄 Transaksi Baru</button>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
let cart={};
let payMethod='cash';

function addToCart(el){
    const id=el.dataset.id, name=el.dataset.name;
    const price=parseFloat(el.dataset.price), stock=parseInt(el.dataset.stock);
    if(!cart[id]) cart[id]={id,name,price,stock,qty:0};
    if(cart[id].qty>=stock){showToast('Stok tidak mencukupi!','error');return;}
    cart[id].qty++;
    el.style.transform='scale(.94)';
    setTimeout(()=>el.style.transform='',130);
    renderCart();
}

function removeItem(id){delete cart[id];renderCart();}

function changeQty(id,d){
    if(!cart[id])return;
    cart[id].qty+=d;
    if(cart[id].qty<=0){delete cart[id];}
    else if(cart[id].qty>cart[id].stock){cart[id].qty=cart[id].stock;showToast('Stok tidak mencukupi!','error');}
    renderCart();
}

function renderCart(){
    const items=Object.values(cart);
    const total=items.reduce((s,i)=>s+i.qty,0);
    document.getElementById('cartCount').textContent=total+' item';

    const ci=document.getElementById('cartItems');
    // Remove old cart-items
    [...ci.children].forEach(c=>{if(c.id!=='cartEmpty')c.remove();});

    if(!items.length){
        document.getElementById('cartEmpty').style.display='flex';
        document.getElementById('cartEmpty').style.flexDirection='column';
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
            <div style="display:flex;flex-direction:column;align-items:flex-end;justify-content:space-between;gap:.25rem;flex-shrink:0">
                <button onclick="removeItem('${item.id}')" style="background:none;border:none;cursor:pointer;color:var(--danger);font-size:1.25rem;line-height:1;padding:.125rem">×</button>
                <span style="font-weight:800;font-size:.875rem;color:var(--text-primary)">${fmt(item.price*item.qty)}</span>
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

function getTotal(){
    const items=Object.values(cart);
    const sub=items.reduce((s,i)=>s+i.price*i.qty,0);
    const disc=parseFloat(document.getElementById('discountInput').value)||0;
    return Math.max(0,sub-disc);
}

// Search
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

// Payment modal
document.getElementById('payModal').addEventListener('transitionend',()=>{});

// Override openModal for pay modal
const origOpen=openModal;
window.openModal=function(id){
    if(id==='payModal'){
        if(!Object.keys(cart).length)return;
        document.getElementById('modalTotal').textContent=fmt(getTotal());
        document.getElementById('payAmount').value='';
        document.getElementById('changeBox').style.display='none';
        document.querySelectorAll('.pay-method-btn').forEach((b,i)=>{
            b.classList.toggle('on',i===0);
        });
        payMethod='cash';
        document.getElementById('cashGroup').style.display='block';
    }
    document.getElementById(id).classList.add('open');
};

function selMethod(m,btn){
    payMethod=m;
    document.querySelectorAll('.pay-method-btn').forEach(b=>b.classList.remove('on'));
    btn.classList.add('on');
    document.getElementById('cashGroup').style.display=m==='cash'?'block':'none';
    if(m!=='cash') document.getElementById('changeBox').style.display='none';
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

async function processTrx(){
    const total=getTotal();
    let pay=payMethod==='cash'?parseFloat(document.getElementById('payAmount').value)||0:total;
    if(payMethod==='cash'&&pay<total){showToast('Uang pembayaran kurang!','error');return;}
    const btn=document.getElementById('processBtn');
    btn.disabled=true;btn.textContent='⏳ Memproses…';

    try{
        const res=await fetch('/api/transactions',{
            method:'POST',
            headers:{'Content-Type':'application/json','X-CSRF-TOKEN':document.querySelector('meta[name="csrf-token"]').content},
            body:JSON.stringify({
                items:Object.values(cart).map(i=>({product_id:parseInt(i.id),quantity:i.qty})),
                pay_amount:pay,
                payment_method:payMethod,
                discount_amount:parseFloat(document.getElementById('discountInput').value)||0,
            })
        });
        const data=await res.json();
        if(data.success){
            closeModal('payModal');
            document.getElementById('invNumber').textContent=data.data.invoice_number;
            document.getElementById('finalChange').textContent=fmt(Math.max(0,pay-total));
            openModal('successModal');
        } else {
            showToast(data.message||'Transaksi gagal!','error');
        }
    } catch(e){showToast('Terjadi kesalahan. Coba lagi.','error');}
    finally{btn.disabled=false;btn.textContent='✓ Konfirmasi Bayar';}
}

function resetPOS(){
    cart={};
    document.getElementById('discountInput').value=0;
    renderCart();
    closeModal('successModal');
    // Refresh product stocks
    location.reload();
}
</script>
@endpush
