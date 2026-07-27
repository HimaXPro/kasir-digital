@extends('layouts.app')
@section('title', 'Manajemen Produk')
@section('breadcrumb', 'Produk')

@section('content')
<div class="page-header d-flex ai-c jb">
    <div>
        <h1 class="page-title">📦 Manajemen Produk</h1>
        <p class="page-sub">{{ $products->total() }} produk terdaftar dalam sistem</p>
    </div>
    <a href="{{ route('products.create') }}" class="btn btn-primary">
        <svg style="width:15px;height:15px;stroke:#fff;fill:none;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
        Tambah Produk
    </a>
</div>

<!-- Filter Bar -->
<div class="card mb-4">
    <div class="card-body" style="padding:.875rem 1.25rem">
        <form method="GET" action="{{ route('products.index') }}" class="d-flex ai-c gap-3 flex-wrap">
            <div class="input-icon" style="flex:1;min-width:200px">
                <svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
                <input type="text" name="search" class="form-control" placeholder="Cari nama atau SKU…" value="{{ request('search') }}">
            </div>
            <select name="category_id" class="form-control" style="width:180px">
                <option value="">Semua Kategori</option>
                @foreach($categories as $cat)
                <option value="{{ $cat->id }}" {{ request('category_id')==$cat->id?'selected':'' }}>{{ $cat->name }}</option>
                @endforeach
            </select>
            <button type="submit" class="btn btn-primary">Filter</button>
            @if(request()->hasAny(['search','category_id']))
            <a href="{{ route('products.index') }}" class="btn btn-ghost">Reset</a>
            @endif
        </form>
    </div>
</div>

<!-- Products Table -->
<div class="card">
    <div class="tbl-wrap">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Produk</th>
                    <th>SKU</th>
                    <th>Kategori</th>
                    <th class="text-right">Harga Modal</th>
                    <th class="text-right">Harga Jual</th>
                    <th class="text-right">Margin</th>
                    <th class="text-center">Stok</th>
                    <th class="text-center">Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($products as $product)
                @php
                    $margin = $product->selling_price > 0
                        ? round((($product->selling_price - $product->cost_price) / $product->selling_price) * 100, 1)
                        : 0;
                @endphp
                <tr>
                    <td class="text-muted fs-xs">{{ $loop->iteration }}</td>
                    <td>
                        <div class="fw-6" style="color:var(--text-primary)">{{ $product->name }}</div>
                    </td>
                    <td><span class="badge b-secondary" style="font-family:monospace">{{ $product->sku }}</span></td>
                    <td>
                        @if($product->category)
                        <span class="badge b-primary">{{ $product->category->name }}</span>
                        @else
                        <span class="text-muted fs-xs">—</span>
                        @endif
                    </td>
                    <td class="text-right text-muted">Rp {{ number_format($product->cost_price, 0, ',', '.') }}</td>
                    <td class="text-right fw-7">Rp {{ number_format($product->selling_price, 0, ',', '.') }}</td>
                    <td class="text-right">
                        <span class="badge {{ $margin >= 30 ? 'b-success' : ($margin >= 15 ? 'b-warning' : 'b-danger') }}">{{ $margin }}%</span>
                    </td>
                    <td class="text-center">
                        <span class="badge {{ $product->stock > 10 ? 'b-success' : ($product->stock > 0 ? 'b-warning' : 'b-danger') }}">
                            {{ $product->stock }} unit
                        </span>
                    </td>
                    <td class="text-center">
                        <div class="d-flex ai-c gap-2" style="justify-content:center">
                            <a href="{{ route('products.edit', $product) }}" class="btn btn-ghost btn-sm btn-icon" title="Edit">
                                <svg style="width:15px;height:15px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                            </a>
                            <form method="POST" action="{{ route('products.destroy', $product) }}" onsubmit="return confirm('Hapus produk ini?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn btn-ghost btn-sm btn-icon" title="Hapus" style="color:var(--danger)">
                                    <svg style="width:15px;height:15px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr><td colspan="9">
                    <div class="empty-state"><div class="empty-icon">📦</div><div class="empty-title">Belum ada produk</div><div class="empty-sub">Klik "Tambah Produk" untuk mulai</div></div>
                </td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    @if($products->hasPages())
    <div style="padding:.875rem 1.25rem;border-top:1px solid var(--border);display:flex;justify-content:flex-end">
        {{ $products->links() }}
    </div>
    @endif
</div>
@endsection
