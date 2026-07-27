@extends('layouts.app')
@section('title', 'Manajemen Kategori')
@section('breadcrumb', 'Kategori')

@section('content')
<div class="page-header d-flex ai-c jb">
    <div>
        <h1 class="page-title">🏷️ Manajemen Kategori</h1>
        <p class="page-sub">{{ $categories->count() }} kategori terdaftar</p>
    </div>
    <button class="btn btn-primary" onclick="openModal('addCatModal')">
        <svg style="width:15px;height:15px;stroke:#fff;fill:none;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>
        Tambah Kategori
    </button>
</div>

<div class="gc2">
    <!-- Category List -->
    <div class="card" style="grid-column:1/-1">
        <div class="tbl-wrap">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Nama Kategori</th>
                        <th>Slug</th>
                        <th class="text-center">Jumlah Produk</th>
                        <th class="text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($categories as $cat)
                    <tr>
                        <td class="text-muted fs-xs">{{ $loop->iteration }}</td>
                        <td class="fw-6">{{ $cat->name }}</td>
                        <td><span class="badge b-secondary" style="font-family:monospace">{{ $cat->slug }}</span></td>
                        <td class="text-center">
                            <span class="badge {{ $cat->products_count > 0 ? 'b-primary' : 'b-secondary' }}">{{ $cat->products_count }} produk</span>
                        </td>
                        <td class="text-center">
                            <div class="d-flex ai-c gap-2" style="justify-content:center">
                                <button class="btn btn-ghost btn-sm btn-icon" title="Edit"
                                    onclick="editCat({{ $cat->id }},'{{ addslashes($cat->name) }}')">
                                    <svg style="width:15px;height:15px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                                </button>
                                <form method="POST" action="{{ route('categories.destroy', $cat) }}" onsubmit="return confirm('Hapus kategori ini?')">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn btn-ghost btn-sm btn-icon" title="Hapus" style="color:var(--danger)">
                                        <svg style="width:15px;height:15px;stroke:currentColor;fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="5">
                        <div class="empty-state"><div class="empty-icon">🏷️</div><div class="empty-title">Belum ada kategori</div></div>
                    </td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Add Modal -->
<div class="modal-ov" id="addCatModal">
    <div class="modal modal-sm">
        <div class="modal-header">
            <span class="modal-title">Tambah Kategori Baru</span>
            <button class="btn btn-ghost btn-icon" onclick="closeModal('addCatModal')" style="font-size:1.125rem">✕</button>
        </div>
        <form method="POST" action="{{ route('categories.store') }}">
            @csrf
            <div class="modal-body">
                <div class="form-group mb-0">
                    <label class="form-label">Nama Kategori <span class="req">*</span></label>
                    <input type="text" name="name" class="form-control" placeholder="Contoh: Makanan, Minuman…" required autofocus>
                    <div class="form-hint">Slug akan dibuat otomatis dari nama</div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline" onclick="closeModal('addCatModal')">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan</button>
            </div>
        </form>
    </div>
</div>

<!-- Edit Modal -->
<div class="modal-ov" id="editCatModal">
    <div class="modal modal-sm">
        <div class="modal-header">
            <span class="modal-title">Edit Kategori</span>
            <button class="btn btn-ghost btn-icon" onclick="closeModal('editCatModal')" style="font-size:1.125rem">✕</button>
        </div>
        <form method="POST" id="editCatForm">
            @csrf @method('PUT')
            <div class="modal-body">
                <div class="form-group mb-0">
                    <label class="form-label">Nama Kategori <span class="req">*</span></label>
                    <input type="text" name="name" id="editCatName" class="form-control" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline" onclick="closeModal('editCatModal')">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan Perubahan</button>
            </div>
        </form>
    </div>
</div>
@endsection

@push('scripts')
<script>
function editCat(id, name){
    document.getElementById('editCatForm').action=`/categories/${id}`;
    document.getElementById('editCatName').value=name;
    openModal('editCatModal');
}
@if($errors->any())
openModal('addCatModal');
@endif
</script>
@endpush
