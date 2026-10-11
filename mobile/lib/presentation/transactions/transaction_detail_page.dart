import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../repositories/transaction_repository.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/pushed_page.dart';
import '../../widgets/tx_tile.dart';
import '../pos/receipt_page.dart';

/// Buka detail transaksi; selesai (kembali) bila ada perubahan agar pemanggil memuat ulang.
Future<void> openTransaction(BuildContext context, int id) {
  return Navigator.of(context).push<void>(MaterialPageRoute<void>(
    builder: (_) => PushedPage(title: 'Detail Transaksi', child: TransactionDetailBody(transactionId: id)),
  ));
}

class TransactionDetailBody extends StatefulWidget {
  const TransactionDetailBody({super.key, required this.transactionId});

  final int transactionId;

  @override
  State<TransactionDetailBody> createState() => _TransactionDetailBodyState();
}

class _TransactionDetailBodyState extends State<TransactionDetailBody> {
  int _version = 0;
  bool _busy = false;

  Future<TransactionModel> _load() => context.read<TransactionRepository>().detail(widget.transactionId);

  void _openReceipt() {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => ReceiptPage(transactionId: widget.transactionId),
    ));
  }

  Future<void> _delete(TransactionModel tx) async {
    final repo = context.read<TransactionRepository>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Hapus transaksi?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NO ${tx.number} · ${tx.patientName} · ${rp(tx.total)}'),
          const SizedBox(height: 6),
          const Text(
            'Transaksi tidak benar-benar dihapus (soft delete). Tidak masuk laporan aktif, tetapi tetap tercatat untuk audit.',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(controller: controller, autofocus: true, decoration: appInput('Alasan penghapusan', hint: 'mis. Kesalahan input')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.length < 3) return;
              Navigator.of(ctx).pop(v);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    await _act(() => repo.delete(widget.transactionId, reason), 'Transaksi dihapus.');
  }

  Future<void> _restore() async {
    final repo = context.read<TransactionRepository>();
    final ok = await confirmDialog(context,
        title: 'Pulihkan transaksi?', message: 'Transaksi akan kembali aktif dan masuk laporan.', confirmLabel: 'Pulihkan');
    if (!ok || !mounted) return;
    await _act(() => repo.restore(widget.transactionId), 'Transaksi dipulihkan.');
  }

  Future<void> _act(Future<TransactionModel> Function() job, String success) async {
    setState(() => _busy = true);
    try {
      await job();
      if (!mounted) return;
      showSnack(context, success);
      setState(() => _version++);
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<AuthController>().isOwner;
    return AsyncView<TransactionModel>(
      loader: _load,
      version: _version,
      builder: (context, tx) => ListView(padding: const EdgeInsets.all(16), children: [
        ContentWidth(maxWidth: 720, child: _content(tx, owner)),
      ]),
    );
  }

  Widget _content(TransactionModel tx, bool owner) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (tx.isDeleted)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DIHAPUS OLEH OWNER',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Oleh: ${tx.deletedByName ?? 'Owner'}\nWaktu: ${dateTimeShort(tx.deletedAt)}\nAlasan: ${tx.deletionReason ?? '-'}',
                style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 4),
            const Text('Tidak masuk laporan, grafik, dan total penjualan aktif.',
                style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ]),
        ),
      whiteCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('NO ${tx.number}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            StatusPill(text: tx.isDeleted ? 'DIHAPUS' : 'SELESAI', danger: tx.isDeleted),
          ]),
          const SizedBox(height: 8),
          _kv('Tanggal', dateTimeShort(tx.date)),
          _kv('Nama Pasien', tx.patientName),
          _kv('Dokter', tx.doctorName),
          _kv('Kasir', tx.cashierName),
          _kv('Cara Pembayaran', tx.paymentMethod),
        ]),
      ),
      const SizedBox(height: 12),
      whiteCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          for (final i in tx.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${i.quantity}${i.unit != null ? ' ${i.unit}' : ''} × ${rp(i.price)} · ${i.categoryName}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
                Text(rp(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          const Divider(color: AppColors.line),
          _money('Total', tx.total, bold: true),
          _money('Dibayar', tx.payment),
          _money('Kembalian', tx.change),
          const SizedBox(height: 4),
          Text('Terbilang: ${tx.totalWords}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
        ]),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _openReceipt,
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Lihat Struk / Print'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
      if (owner && !tx.isDeleted) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _delete(tx),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus Transaksi (Owner)'),
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
      if (owner && tx.isDeleted) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.restore),
          label: const Text('Pulihkan Transaksi'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
    ]);
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: AppColors.muted))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _money(String label, int value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          const Spacer(),
          Text(rp(value), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 18 : 14, color: AppColors.navy)),
        ]),
      );
}
