import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/icon_helpers.dart';
import '../../core/icon_registry.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';
import '../../repositories/catalog_repository.dart';
import '../../widgets/common.dart';

/// Tambah / ubah produk (Owner). Perubahan harga TIDAK mengubah transaksi lama (snapshot).
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  List<ProductCategory> _categories = const [];
  int? _categoryId;
  String? _iconName;
  bool _priceEditable = false;
  bool _active = true;
  bool _saving = false;
  String? _loadError;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _unit = TextEditingController(text: p?.unit ?? '');
    _price = TextEditingController(text: p == null || p.salePrice == 0 ? '' : thousands(p.salePrice));
    final costValue = p?.costPrice;
    _cost = TextEditingController(text: costValue == null ? '' : thousands(costValue.round()));
    _categoryId = p?.categoryId;
    _iconName = p?.iconName;
    _priceEditable = p?.priceEditable ?? false;
    _active = p?.isActive ?? true;
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final repo = context.read<CatalogRepository>();
    try {
      final cats = await repo.categories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _categoryId ??= cats.isEmpty ? null : cats.first.id;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = errorMessage(e));
    }
  }

  String get _categoryName {
    for (final c in _categories) {
      if (c.id == _categoryId) return c.name;
    }
    return widget.product?.categoryName ?? '';
  }

  Future<void> _pickIcon() async {
    final names = kIconNames.toList()..sort();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Pilih icon', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 76, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: names.length,
                itemBuilder: (c, i) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(ctx).pop(names[i]),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.veryLightBlue, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: ItemIcon(iconName: names[i], categoryName: '', size: 40)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    if (picked != null) setState(() => _iconName = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      showSnack(context, 'Pilih kategori terlebih dahulu.', error: true);
      return;
    }
    final repo = context.read<CatalogRepository>();
    final price = parseDigits(_price.text);
    final cost = _cost.text.trim().isEmpty ? null : parseDigits(_cost.text);
    final unit = _unit.text.trim();
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await repo.updateProduct(widget.product!.id, {
          'name': _name.text.trim(),
          'category_id': _categoryId,
          'sale_price': price,
          'price_editable': _priceEditable,
          'is_active': _active,
          if (_iconName != null) 'icon_name': _iconName,
          if (unit.isEmpty) 'clear_unit': true else 'unit': unit,
          if (cost == null) 'clear_cost': true else 'cost_price': cost,
        });
      } else {
        await repo.createProduct({
          'name': _name.text.trim(),
          'category_id': _categoryId,
          'sale_price': price,
          'price_editable': _priceEditable,
          'is_active': _active,
          if (_iconName != null) 'icon_name': _iconName,
          if (unit.isNotEmpty) 'unit': unit,
          if (cost != null) 'cost_price': cost,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconName = resolveIconName(_iconName, _categoryName);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_isEdit ? 'Ubah Produk' : 'Tambah Produk', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          ContentWidth(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.veryLightBlue, borderRadius: BorderRadius.circular(18)),
                  child: Center(child: ItemIcon(iconName: iconName, categoryName: _categoryName, size: 48)),
                ),
                const SizedBox(width: 14),
                OutlinedButton.icon(onPressed: _pickIcon, icon: const Icon(Icons.image_outlined), label: const Text('Ganti icon')),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: appInput('Nama produk / jasa / tindakan'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi.' : null,
              ),
              const SizedBox(height: 14),
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 8),
              if (_loadError != null)
                Text(_loadError!, style: const TextStyle(color: AppColors.danger))
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in _categories)
                    PillChip(label: c.name, selected: _categoryId == c.id, onTap: () => setState(() => _categoryId = c.id)),
                ]),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unit,
                decoration: appInput('Satuan (opsional)', hint: 'pcs / ampul - kosongkan untuk jasa'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: appInput('Harga jual (Rp)'),
                validator: (v) => (!_priceEditable && parseDigits(v ?? '') <= 0) ? 'Harga jual wajib diisi.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cost,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: appInput('Harga modal (opsional)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Harga bebas'),
                subtitle: const Text('Kasir mengisi harga saat transaksi (paket/tindakan yang nominalnya berbeda-beda).'),
                value: _priceEditable,
                onChanged: (v) => setState(() => _priceEditable = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                subtitle: const Text('Produk nonaktif tidak tampil di kasir.'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              if (_isEdit)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Text('Mengubah harga tidak mengubah transaksi lama.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
