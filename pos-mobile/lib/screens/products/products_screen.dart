import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/category.dart';
import '../../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _api = ApiService();
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  String _search = '';
  int? _filterCatId;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 100 &&
        !_loadingMore &&
        _page < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) setState(() { _loading = true; _error = null; _page = 1; });
    try {
      final results = await Future.wait([
        _api.get('/products', queryParams: {
          'page': '1',
          'per_page': '20',
          if (_search.isNotEmpty) 'search': _search,
          if (_filterCatId != null) 'category_id': '$_filterCatId',
        }),
        _api.get('/categories'),
      ]);
      setState(() {
        _products = (results[0]['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        _lastPage = results[0]['meta']?['last_page'] as int? ?? 1;
        _categories = (results[1]['data'] as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() { _loadingMore = true; _page++; });
    try {
      final result = await _api.get('/products', queryParams: {
        'page': '$_page',
        'per_page': '20',
        if (_search.isNotEmpty) 'search': _search,
        if (_filterCatId != null) 'category_id': '$_filterCatId',
      });
      setState(() {
        _products.addAll((result['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>)));
        _lastPage = result['meta']?['last_page'] as int? ?? 1;
      });
    } catch (_) {} finally {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Produk', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Hapus "${product.name}"? Tindakan ini tidak bisa dibatalkan.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.delete('/products/${product.id}');
        setState(() => _products.removeWhere((p) => p.id == product.id));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} berhasil dihapus'),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _openForm({Product? product}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          product: product,
          categories: _categories,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primary,
                        child: _buildList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Produk',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _search = v);
              _loadData();
            },
            decoration: InputDecoration(
              hintText: 'Cari nama produk atau SKU…',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                        _loadData();
                      },
                    )
                  : null,
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'Semua'),
                  ..._categories.map((c) => _filterChip(c.id, c.name)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(int? catId, String label) {
    final isSelected = _filterCatId == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _filterCatId = catId);
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text('Gagal memuat produk',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );

  Widget _buildList() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('Belum ada produk',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Produk'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: _products.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == _products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
            ),
          );
        }
        return _buildProductTile(_products[i]);
      },
    );
  }

  Widget _buildProductTile(Product product) {
    final stockColor = product.stock > 10
        ? AppTheme.success
        : product.stock > 0
            ? AppTheme.warning
            : AppTheme.danger;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          product.name,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              formatRupiah(product.sellingPrice),
              style: GoogleFonts.inter(
                  color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  product.stock <= 0 ? 'Habis' : 'Stok: ${product.stock}',
                  style: GoogleFonts.inter(color: stockColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                if (product.category != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category!.name,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
              onPressed: () => _openForm(product: product),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
              onPressed: () => _deleteProduct(product),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Form Screen ──────────────────────────────────────────────────────
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final List<Category> categories;

  const ProductFormScreen({super.key, this.product, required this.categories});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  bool _loading = false;

  late final _nameCtrl = TextEditingController(text: widget.product?.name);
  late final _skuCtrl = TextEditingController(text: widget.product?.sku);
  late final _costCtrl = TextEditingController(
      text: widget.product?.costPrice.toStringAsFixed(0));
  late final _priceCtrl = TextEditingController(
      text: widget.product?.sellingPrice.toStringAsFixed(0));
  late final _stockCtrl = TextEditingController(
      text: widget.product?.stock.toString());
  int? _categoryId;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {
        if (_categoryId != null) 'category_id': _categoryId,
        'name': _nameCtrl.text.trim(),
        'sku': _skuCtrl.text.trim(),
        'cost_price': double.parse(_costCtrl.text),
        'selling_price': double.parse(_priceCtrl.text),
        'stock': int.parse(_stockCtrl.text),
      };

      if (_isEdit) {
        await _api.put('/products/${widget.product!.id}', body);
      } else {
        await _api.post('/products', body);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                : Text(
                    'Simpan',
                    style: GoogleFonts.inter(
                        color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Informasi Dasar', [
              _buildField('Nama Produk', _nameCtrl,
                  hint: 'Contoh: Nasi Goreng Spesial',
                  validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null),
              const SizedBox(height: 12),
              _buildField('SKU', _skuCtrl,
                  hint: 'Contoh: NGS-001',
                  validator: (v) => v!.isEmpty ? 'SKU tidak boleh kosong' : null),
              const SizedBox(height: 12),
              _buildDropdown('Kategori', _categoryId, widget.categories),
            ]),
            const SizedBox(height: 16),
            _buildSection('Harga & Stok', [
              _buildField('Harga Modal (Rp)', _costCtrl,
                  hint: '0', isNumber: true,
                  validator: (v) => v!.isEmpty ? 'Harga modal wajib diisi' : null),
              const SizedBox(height: 12),
              _buildField('Harga Jual (Rp)', _priceCtrl,
                  hint: '0', isNumber: true,
                  validator: (v) => v!.isEmpty ? 'Harga jual wajib diisi' : null),
              const SizedBox(height: 12),
              _buildField('Stok', _stockCtrl,
                  hint: '0', isNumber: true, isInt: true,
                  validator: (v) => v!.isEmpty ? 'Stok wajib diisi' : null),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String? hint, bool isNumber = false, bool isInt = false, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber
              ? (isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true))
              : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, int? value, List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int?>(
          initialValue: value,
          decoration: const InputDecoration(),

          hint: Text('Pilih kategori (opsional)',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Tanpa Kategori',
                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
            ),
            ...categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
      ],
    );
  }
}
