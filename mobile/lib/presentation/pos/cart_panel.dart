import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/cart_line.dart';
import '../../state/cart_controller.dart';
import '../../widgets/common.dart';
import 'product_card.dart';

/// Panel "Detail Transaksi": nomor, nama pasien (diketik kasir), dokter tetap, item, total, pembayaran, kembalian.
class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.patientController,
    required this.paymentController,
    required this.nextNumber,
    required this.onSubmit,
    this.scrollAll = false,
  });

  final TextEditingController patientController;
  final TextEditingController paymentController;
  final String? nextNumber;
  final VoidCallback onSubmit;

  /// true: seluruh panel bisa digulir (bottom sheet di HP). false: daftar item digulir, tombol bayar tetap terlihat.
  final bool scrollAll;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final header = _header(cart);
    final footer = _footer(context, cart);

    if (scrollAll) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ...header,
          const SizedBox(height: 10),
          if (cart.isEmpty) _emptyItems() else ...[for (final l in cart.lines) _LineTile(line: l)],
          const SizedBox(height: 10),
          ...footer,
        ]),
      );
    }

    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ...header,
        const SizedBox(height: 8),
        Expanded(
          child: cart.isEmpty
              ? _emptyItems()
              : ListView.builder(
                  itemCount: cart.itemCount,
                  itemBuilder: (context, i) => _LineTile(line: cart.lines[i]),
                ),
        ),
        const SizedBox(height: 8),
        ...footer,
      ]),
    );
  }

  Widget _emptyItems() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text('Belum ada item.\nPilih obat, jasa, atau tindakan.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        ),
      );

  List<Widget> _header(CartController cart) {
    return [
      Row(children: [
        const Expanded(
          child: Text('Detail Transaksi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        if (!cart.isEmpty)
          TextButton.icon(
            onPressed: () {
              cart.clear();
              patientController.clear();
              paymentController.clear();
            },
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Kosongkan'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
      ]),
      Text('NO : ${nextNumber ?? '-'}  (otomatis saat disimpan)',
          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 10),
      TextField(
        controller: patientController,
        onChanged: cart.setPatientName,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: appInput('Nama Pasien', hint: 'Masukkan nama pasien', prefix: const Icon(Icons.person_outline)),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
        child: Row(children: const [
          Icon(Icons.medical_services_outlined, size: 18, color: AppColors.navy),
          SizedBox(width: 8),
          Text('Dokter: ', style: TextStyle(color: AppColors.muted)),
          Expanded(child: Text(AppConfig.doctorName, style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
      ),
    ];
  }

  List<Widget> _footer(BuildContext context, CartController cart) {
    final cash = cart.paymentMethod == 'Cash';
    final showShort = cash && cart.payment > 0 && !cart.paymentEnough && cart.total > 0;
    return [
      const Divider(color: AppColors.line),
      Row(children: [
        const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(rp(cart.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in AppConfig.paymentMethods)
          PillChip(
            label: m,
            selected: cart.paymentMethod == m,
            onTap: () {
              cart.setPaymentMethod(m);
              if (m != 'Cash') paymentController.clear();
            },
          ),
      ]),
      const SizedBox(height: 10),
      if (cash) ...[
        TextField(
          controller: paymentController,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsInputFormatter()],
          onChanged: (v) => cart.setPayment(parseDigits(v)),
          decoration: appInput('Nominal pembayaran', hint: '0', prefix: const Padding(
            padding: EdgeInsets.only(left: 14, right: 6),
            child: Align(widthFactor: 1, child: Text('Rp', style: TextStyle(fontWeight: FontWeight.w700))),
          )),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final v in _quickAmounts(cart.total))
            ActionChip(
              backgroundColor: AppColors.veryLightBlue,
              side: BorderSide.none,
              labelStyle: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
              label: Text(v == cart.total ? 'Uang pas' : thousands(v)),
              onPressed: () {
                paymentController.text = thousands(v);
                cart.setPayment(v);
              },
            ),
        ]),
        const SizedBox(height: 8),
      ],
      if (showShort)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
          child: const Text('Nominal pembayaran belum mencukupi.', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
        ),
      Row(children: [
        const Text('Kembalian', style: TextStyle(fontSize: 15)),
        const Spacer(),
        Text(rp(cart.paymentEnough ? cart.change : 0),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: cart.canSubmit ? onSubmit : null,
        icon: cart.submitting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : const Icon(Icons.payments_outlined),
        label: Text(cart.submitting ? 'Menyimpan...' : 'Bayar & Simpan',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      if (!cart.isEmpty && !cart.patientValid)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Nama pasien wajib diisi.', style: TextStyle(color: AppColors.danger, fontSize: 12.5)),
        ),
    ];
  }

  /// Uang pas + pembulatan ke atas (10rb / 50rb / 100rb).
  List<int> _quickAmounts(int total) {
    if (total <= 0) return const [];
    final out = <int>{total};
    for (final step in [10000, 50000, 100000]) {
      final up = ((total + step - 1) ~/ step) * step;
      if (up > total) out.add(up);
    }
    final list = out.toList()..sort();
    return list.take(4).toList();
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    final p = line.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ItemIcon(iconName: p.iconName, categoryName: p.categoryName, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: p.priceEditable
                  ? () async {
                      final v = await askPrice(context, name: p.name, initial: line.unitPrice);
                      if (v != null) cart.setUnitPrice(p.id, v);
                    }
                  : null,
              child: Text(
                '${rp(line.unitPrice)}${p.unit != null ? ' / ${p.unit}' : ''}${p.priceEditable ? '  ✎' : ''}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rp(line.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            RoundIconButton(icon: Icons.remove, onTap: () => cart.decrement(p.id), filled: false, size: 26),
            SizedBox(width: 30, child: Text('${line.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
            RoundIconButton(icon: Icons.add, onTap: () => cart.increment(p.id), filled: true, size: 26),
          ]),
        ]),
      ]),
    );
  }
}
