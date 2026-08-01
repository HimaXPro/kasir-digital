import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_helper.dart';
import '../../models/category.dart';
import '../../models/product.dart';

import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  FirebaseService get _fb => FirebaseService(context.read<AuthProvider>().currentUser!);
  String _search = '';
  String? _filterCatId;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
        await _fb.deleteProduct(product.id);
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

  void _openForm({Product? product, List<Category>? categories}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          product: product,
          categories: categories ?? [],
        ),
      ),
    );
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
      ),
      body: StreamBuilder<List<Category>>(
        stream: _fb.streamCategories(),
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];
          return StreamBuilder<List<Product>>(
            stream: _fb.streamProducts(),
            builder: (context, prodSnapshot) {
              if (prodSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }

              var products = prodSnapshot.data ?? [];

              // Local Filtering
              if (_search.isNotEmpty) {
                products = products
                    .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()) || 
                                  p.sku.toLowerCase().contains(_search.toLowerCase()))
                    .toList();
              }
              if (_filterCatId != null) {
                products = products.where((p) => p.categoryId == _filterCatId).toList();
              }

              return Column(
                children: [
                  _buildSearchFilter(categories),
                  Expanded(
                    child: _buildList(products, categories),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Category>>(
        stream: _fb.streamCategories(),
        builder: (context, snapshot) {
          return FloatingActionButton.extended(
            onPressed: () => _openForm(categories: snapshot.data),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Tambah Produk',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          );
        }
      ),
    );
  }

  Widget _buildSearchFilter(List<Category> categories) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _search = v);
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
                      },
                    )
                  : null,
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'Semua'),
                  ...categories.map((c) => _filterChip(c.id, c.name)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String? catId, String label) {
    final isSelected = _filterCatId == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _filterCatId = catId);
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

  Widget _buildList(List<Product> products, List<Category> categories) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('Belum ada produk',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_filterCatId == null && _search.isEmpty) {
      final Map<String, List<Product>> grouped = {};
      for (var p in products) {
        grouped.putIfAbsent(p.categoryId ?? '', () => []).add(p);
      }

      final List<dynamic> listItems = [];
      for (var cat in categories) {
        if (grouped.containsKey(cat.id)) {
          listItems.add(cat.name);
          listItems.addAll(grouped[cat.id]!);
          grouped.remove(cat.id);
        }
      }
      if (grouped.containsKey('')) {
        listItems.add('Tanpa Kategori');
        listItems.addAll(grouped['']!);
      }
      for (var key in grouped.keys) {
        if (key != '') {
          listItems.add('Kategori Lainnya');
          listItems.addAll(grouped[key]!);
        }
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: listItems.length,
        itemBuilder: (ctx, i) {
          final item = listItems[i];
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Text(item, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildProductTile(item as Product, categories),
            );
          }
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        return _buildProductTile(products[i], categories);
      },
    );
  }

  Widget _buildProductTile(Product product, List<Category> categories) {
    final stockColor = product.stock > 10
        ? AppTheme.success
        : product.stock > 0
            ? AppTheme.warning
            : AppTheme.danger;
            
    final categoryName = categories.where((c) => c.id == product.categoryId).firstOrNull?.name;

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
                if (categoryName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      categoryName,
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
              onPressed: () => _openForm(product: product, categories: categories),
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
  FirebaseService get _fb => FirebaseService(context.read<AuthProvider>().currentUser!);
  bool _loading = false;

  late final _nameCtrl = TextEditingController(text: widget.product?.name);
  late final _skuCtrl = TextEditingController(text: widget.product?.sku);
  late final _costCtrl = TextEditingController(
      text: widget.product?.costPrice.toStringAsFixed(0));
  late final _priceCtrl = TextEditingController(
      text: widget.product?.sellingPrice.toStringAsFixed(0));
  late final _stockCtrl = TextEditingController(
      text: widget.product?.stock.toString());
  String? _categoryId;
  File? _imageFile;
  String? _existingImageUrl;
  final _picker = ImagePicker();

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
    _existingImageUrl = widget.product?.imageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: AppTheme.danger),
      );
    }
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
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        // Convert the compressed file to Base64
        final bytes = await _imageFile!.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      }

      final newProduct = Product(
        id: _isEdit ? widget.product!.id : '',
        categoryId: _categoryId,
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        costPrice: double.parse(_costCtrl.text),
        sellingPrice: double.parse(_priceCtrl.text),
        stock: int.parse(_stockCtrl.text),
        imageUrl: imageUrl,
      );

      if (_isEdit) {
        await _fb.updateProduct(newProduct);
      } else {
        await _fb.addProduct(newProduct);
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
            _buildImagePicker(),
            const SizedBox(height: 16),
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

  Widget _buildDropdown(String label, String? value, List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: value,
          decoration: const InputDecoration(),
          hint: Text('Pilih kategori (opsional)',
              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          items: [
            DropdownMenuItem<String?>(
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

  Widget _buildImagePicker() {
    final hasImage = _imageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto Produk (Opsional)',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageFile != null)
                    Image.file(_imageFile!, fit: BoxFit.cover)
                  else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                    Image(image: getImageProvider(_existingImageUrl!), fit: BoxFit.cover),
                  if (hasImage)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit, color: Colors.white, size: 24),
                            const SizedBox(height: 4),
                            Text('Ganti Foto', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppTheme.textMuted),
                        const SizedBox(height: 4),
                        Text('Pilih Foto',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
