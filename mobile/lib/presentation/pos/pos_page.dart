import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';
import '../../repositories/transaction_repository.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/common.dart';
import 'cart_panel.dart';
import 'product_card.dart';
import 'receipt_page.dart';

/// Layar Transaksi Baru. Tablet: 2 kolom (produk | detail transaksi). HP: produk + keranjang bottom sheet.
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _patient = TextEditingController();
  final TextEditingController _payment = TextEditingController();
  int? _categoryId;
  String _query = '';
  String? _nextNumber;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartController>();
    _patient.text = cart.patientName;
    if (cart.payment > 0) _payment.text = thousands(cart.payment);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogController>().load(force: true);
      _loadNumber();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _patient.dispose();
    _payment.dispose();
    super.dispose();
  }

  Future<void> _loadNumber() async {
    final repo = context.read<TransactionRepository>();
    try {
      final number = await repo.nextNumber();
      if (mounted) setState(() => _nextNumber = number);
    } catch (_) {
      // Nomor hanya perkiraan; nomor final dibuat server saat disimpan.
    }
  }

  Future<void> _onTapProduct(Product p) async {
    final cart = context.read<CartController>();
    if (!cart.contains(p.id) && cart.isFull) {
      showSnack(context, 'Maksimal ${AppConfig.maxItems} item per struk.', error: true);
      return;
    }
    if (p.priceEditable && !cart.contains(p.id)) {
      final price = await askPrice(context, name: p.name, initial: p.salePrice);
      if (price == null || !mounted) return;
      cart.add(p, unitPrice: price);
      return;
    }
    cart.add(p);
  }

  Future<void> _submit() async {
    final cart = context.read<CartController>();
    final repo = context.read<TransactionRepository>();
    FocusScope.of(context).unfocus();
    final tx = await cart.submit(repo);
    if (!mounted) return;
    if (tx == null) {
      showSnack(context, cart.submitError ?? 'Terjadi kesalahan. Silakan coba lagi.', error: true);
      return;
    }
    cart.clear();
    showSnack(context, 'Transaksi berhasil disimpan.');
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.settings.name == '/pos'); // tutup bottom sheet bila terbuka
    navigator.pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ReceiptPage(transactionId: tx.id, afterSave: true),
    ));
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.92;
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: CartPanel(
              patientController: _patient,
              paymentController: _payment,
              nextNumber: _nextNumber,
              onSubmit: _submit,
              scrollAll: true,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Tablet: 2 kolom. HP (termasuk landscape yang pendek): produk + keranjang bottom sheet.
    final wide = size.width >= 840 && size.height >= 600;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(children: const [
          AppLogo(height: 28),
          SizedBox(width: 10),
          Text('Transaksi Baru', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Muat ulang produk',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CatalogController>().load(force: true);
              _loadNumber();
            },
          ),
        ],
      ),
      body: SafeArea(child: wide ? _wideBody() : _narrowBody()),
    );
  }

  Widget _wideBody() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _catalog()),
      SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 12, 12),
          child: CartPanel(
            patientController: _patient,
            paymentController: _payment,
            nextNumber: _nextNumber,
            onSubmit: _submit,
          ),
        ),
      ),
    ]);
  }

  Widget _narrowBody() {
    final cart = context.watch<CartController>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: TextField(
          controller: _patient,
          onChanged: cart.setPatientName,
          textCapitalization: TextCapitalization.words,
          decoration: appInput('Nama Pasien', hint: 'Masukkan nama pasien', prefix: const Icon(Icons.person_outline)),
        ),
      ),
      Expanded(child: _catalog()),
      _CartBar(cart: cart, onOpen: _openSheet),
    ]);
  }

  Widget _catalog() {
    final catalog = context.watch<CatalogController>();
    final cart = context.watch<CartController>();
    final items = catalog.filter(query: _query, categoryId: _categoryId);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          decoration: appInput(
            null,
            hint: 'Cari obat, jasa, tindakan...',
            prefix: const Icon(Icons.search),
            suffix: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          PillChip(label: 'Semua', selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
          for (final c in catalog.categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: PillChip(label: c.name, selected: _categoryId == c.id, onTap: () => setState(() => _categoryId = c.id)),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(child: _grid(catalog, items, cart)),
    ]);
  }

  Widget _grid(CatalogController catalog, List<Product> items, CartController cart) {
    if (catalog.loading && !catalog.loaded) return const LoadingView(message: 'Memuat produk...');
    if (catalog.error != null && !catalog.loaded) {
      return ErrorView(message: catalog.error!, onRetry: () => catalog.load(force: true));
    }
    if (catalog.products.isEmpty) return const EmptyView(message: 'Belum ada produk.');
    if (items.isEmpty) return const EmptyView(message: 'Produk tidak ditemukan.', icon: Icons.search_off);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 196,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        return ProductCard(
          product: p,
          quantity: cart.quantityOf(p.id),
          onTap: () => _onTapProduct(p),
          onIncrement: () => cart.increment(p.id),
          onDecrement: () => cart.decrement(p.id),
        );
      },
    );
  }
}

/// Bar bawah (HP): ringkasan keranjang, ketuk untuk melihat detail & membayar.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart, required this.onOpen});

  final CartController cart;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      child: InkWell(
        onTap: onOpen,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Icon(Icons.shopping_basket_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cart.isEmpty ? 'Keranjang kosong' : '${cart.totalQuantity} item · ${rp(cart.total)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5),
                ),
              ),
              const Text('Lihat & Bayar', style: TextStyle(color: AppColors.lightBlue, fontWeight: FontWeight.w700)),
              const Icon(Icons.keyboard_arrow_up, color: AppColors.lightBlue),
            ]),
          ),
        ),
      ),
    );
  }
}
