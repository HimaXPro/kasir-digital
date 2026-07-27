@extends('layouts.app')
@section('title', 'Edit Produk')
@section('breadcrumb', 'Produk')

@section('content')
<div class="page-header">
    <h1 class="page-title">✏️ Edit Produk</h1>
    <p class="page-sub">Perbarui informasi produk "{{ $product->name }}". Perubahan stok akan otomatis dicatat sebagai mutasi penyesuaian.</p>
</div>

<div style="max-width:640px">
<form method="POST" action="{{ route('products.update', $product) }}">
    @csrf @method('PUT')
    <div class="card">
        <div class="card-header">
            <span class="card-title">Informasi Produk</span>
            <span class="badge b-secondary" style="font-family:monospace">{{ $product->sku }}</span>
        </div>
        <div class="card-body">
            @if($errors->any())
            <div class="alert alert-danger">
                <svg fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
                <div><ul style="margin:0;padding-left:1rem">@foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach</ul></div>
            </div>
            @endif

            <div class="gc2">
                <div class="form-group" style="grid-column:1/-1">
                    <label class="form-label">Nama Produk <span class="req">*</span></label>
                    <input type="text" name="name" class="form-control" value="{{ old('name', $product->name) }}" required>
                </div>

                <div class="form-group">
                    <label class="form-label">SKU / Kode Produk <span class="req">*</span></label>
                    <input type="text" name="sku" class="form-control" value="{{ old('sku', $product->sku) }}" required>
                </div>

                <div class="form-group">
                    <label class="form-label">Kategori</label>
                    <select name="category_id" class="form-control">
                        <option value="">— Tanpa Kategori —</option>
                        @foreach($categories as $cat)
                        <option value="{{ $cat->id }}" {{ old('category_id', $product->category_id)==$cat->id?'selected':'' }}>{{ $cat->name }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="form-group">
                    <label class="form-label">Harga Modal (Rp) <span class="req">*</span></label>
                    <input type="number" name="cost_price" class="form-control" value="{{ old('cost_price', $product->cost_price) }}" min="0" step="100" required oninput="calcMargin()">
                </div>

                <div class="form-group">
                    <label class="form-label">Harga Jual (Rp) <span class="req">*</span></label>
                    <input type="number" name="selling_price" id="sellingPrice" class="form-control" value="{{ old('selling_price', $product->selling_price) }}" min="0" step="100" required oninput="calcMargin()">
                </div>

                <div class="form-group">
                    <label class="form-label">Stok <span class="req">*</span></label>
                    <input type="number" name="stock" class="form-control" value="{{ old('stock', $product->stock) }}" min="0" required>
                    <div class="form-hint">Stok saat ini: <strong>{{ $product->stock }} unit</strong>. Perubahan akan dicatat sebagai penyesuaian.</div>
                </div>
            </div>

            <div id="marginInfo" style="background:var(--success-light);border-radius:var(--radius-sm);padding:.75rem 1rem;font-size:.8125rem;color:#065F46;border:1px solid #A7F3D0">
                <strong>💰 Estimasi Margin: <span id="marginPct">0</span>%</strong>
                &nbsp;|&nbsp; Keuntungan per unit: <strong>Rp <span id="marginAmt">0</span></strong>
            </div>
        </div>
    </div>

    <div class="d-flex ai-c gap-3 mt-4" style="justify-content:flex-end">
        <a href="{{ route('products.index') }}" class="btn btn-outline">Batal</a>
        <button type="submit" class="btn btn-primary btn-lg">💾 Simpan Perubahan</button>
    </div>
</form>
</div>
@endsection

@push('scripts')
<script>
function calcMargin(){
    const cost=parseFloat(document.querySelector('[name=cost_price]').value)||0;
    const sell=parseFloat(document.getElementById('sellingPrice').value)||0;
    if(sell>0){
        const pct=((sell-cost)/sell*100).toFixed(1);
        const amt=new Intl.NumberFormat('id-ID').format(Math.max(0,sell-cost));
        document.getElementById('marginPct').textContent=pct;
        document.getElementById('marginAmt').textContent=amt;
    }
}
calcMargin();
document.querySelector('[name=cost_price]').addEventListener('input',calcMargin);
</script>
@endpush
