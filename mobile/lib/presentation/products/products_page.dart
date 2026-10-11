import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';
import '../../repositories/catalog_repository.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/common.dart';
import 'product_form_page.dart';

/// Daftar produk/jasa/tindakan. Owner: tambah, ubah harga, aktif/nonaktif. Kasir: hanya melihat produk aktif.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.owner});

  final bool owner;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _search = TextEditingController();
  List<ProductCategory> _categories = const [];
  List<Product> _products = const [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<CatalogRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await repo.categories();
      final prods = await repo.products(includeInactive: widget.owner);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _products = prods;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
      });
    }
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    return _products.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      return q.isEmpty || p.name.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggle(Product p, bool value) async {
    final repo = context.read<CatalogRepository>();
    final catalog = context.read<CatalogController>();
    try {
      await repo.updateProduct(p.id, {'is_active': value});
      catalog.load(force: true);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
  }

  Future<void> _edit([Product? product]) async {
    final catalog = context.read<CatalogController>();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ProductFormPage(product: product)),
    );
    if (changed == true) {
      catalog.load(force: true);
      if (mounted) await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.owner
          ? FloatingActionButton.extended(
              onPressed: () => _edit(),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
      body: ContentWidth(
        maxWidth: 900,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: appInput(null, hint: 'Cari obat, jasa, tindakan...', prefix: const Icon(Icons.search)),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              PillChip(label: 'Semua', selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
              for (final c in _categories)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: PillChip(label: c.name, selected: _categoryId == c.id, onTap: () => setState(() => _categoryId = c.id)),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body()),
        ]),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_products.isEmpty) return const EmptyView(message: 'Belum ada produk.', icon: Icons.medication_outlined);
    final items = _filtered;
    if (items.isEmpty) return const EmptyView(message: 'Produk tidak ditemukan.', icon: Icons.search_off);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12, 4, 12, widget.owner ? 88 : 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _tile(items[i]),
    );
  }

  Widget _tile(Product p) {
    final sub = StringBuffer(p.categoryName);
    if (p.unit != null && p.unit!.isNotEmpty) sub.write(' · ${p.unit}');
    return Opacity(
      opacity: p.isActive ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.owner ? () => _edit(p) : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.veryLightBlue, borderRadius: BorderRadius.circular(12)),
                child: Center(child: ItemIcon(iconName: p.iconName, categoryName: p.categoryName, size: 32)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(sub.toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 2),
                  Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(p.priceEditable && p.salePrice == 0 ? 'Harga bebas' : rp(p.salePrice),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                    if (p.priceEditable) const StatusPill(text: 'Harga bebas'),
                    if (!p.isActive) const StatusPill(text: 'Nonaktif', danger: true),
                    if (widget.owner && p.costPrice != null)
                      Text('Modal ${rp(p.costPrice!.round())}', style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ]),
                ]),
              ),
              if (widget.owner) Switch(value: p.isActive, onChanged: (v) => _toggle(p, v)),
            ]),
          ),
        ),
      ),
    );
  }
}
