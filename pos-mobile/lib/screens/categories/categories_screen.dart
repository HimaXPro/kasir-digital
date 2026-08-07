import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';

import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  FirebaseService get _fb => FirebaseService(context.read<AuthProvider>().currentUser!);

  void _showForm({Category? category}) {
    final nameCtrl = TextEditingController(text: category?.name);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                category == null ? 'Tambah Kategori' : 'Edit Kategori',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (ctx2, setSt) => Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kategori',
                          hintText: 'Contoh: Minuman',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSt(() => saving = true);
                                  final nav = Navigator.of(ctx);
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    if (category == null) {
                                      await _fb.addCategory(Category(id: '', name: nameCtrl.text.trim()));
                                    } else {
                                      await _fb.updateCategory(Category(id: category.id, name: nameCtrl.text.trim()));
                                    }
                                    nav.pop();
                                  } catch (e) {
                                    messenger..clearSnackBars()..showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                                    );
                                  } finally {
                                    if (mounted) setSt(() => saving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: saving
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text(
                                  category == null ? 'Tambah' : 'Simpan',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Kategori', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Hapus "${category.name}"?', style: GoogleFonts.inter(fontSize: 14)),
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
        await _fb.deleteCategory(category.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(
            content: Text('${category.name} berhasil dihapus'),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
      ),
      body: StreamBuilder<List<Category>>(
        stream: _fb.streamCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }
          
          final categories = List<Category>.from(snapshot.data ?? []);
          
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📂', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('Belum ada kategori',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = categories.removeAt(oldIndex);
              categories.insert(newIndex, item);
              
              _fb.reorderCategories(categories);
            },
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return Container(
                key: ValueKey(cat.id),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [AppTheme.shadowSm],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.drag_indicator, color: AppTheme.textMuted),
                  title: Text(cat.name,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
                        onPressed: () => _showForm(category: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.danger, size: 18),
                        onPressed: () => _delete(cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Kategori',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
