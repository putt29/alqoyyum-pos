import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../models/receipt.dart';
import '../../receipt/receipt_export.dart';
import '../../receipt/receipt_view.dart';
import '../../repositories/transaction_repository.dart';
import '../../services/file_service.dart';
import '../../widgets/common.dart';

/// Preview struk B5 (176:250). Print, Download PNG, dan Bagikan memakai template yang SAMA.
class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, required this.transactionId, this.afterSave = false});

  final int transactionId;
  final bool afterSave;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  late Future<ReceiptDoc> _future;
  bool _busy = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<TransactionRepository>().receipt(widget.transactionId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage('assets/images/logo_mark.png'), context);
    }
  }

  void _reload() {
    setState(() {
      _future = context.read<TransactionRepository>().receipt(widget.transactionId);
    });
  }

  Future<void> _run(Future<void> Function() job, String failMessage) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (_) {
      if (mounted) showSnack(context, failMessage, error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  String _number(ReceiptDoc doc) => doc.numberLine.replaceFirst('NO :', '').trim();
  String _fileName(ReceiptDoc doc) => '${safeFileName('Struk_${_number(doc)}')}.png';

  Future<void> _print(ReceiptDoc doc) async {
    final png = await ReceiptExporter.capturePng(_boundaryKey);
    await ReceiptExporter.printPng(png, 'Struk_${safeFileName(_number(doc))}');
  }

  Future<void> _download(ReceiptDoc doc) async {
    final png = await ReceiptExporter.capturePng(_boundaryKey);
    final name = _fileName(doc);
    await FileService.savePngToGallery(png, name);
    if (mounted) showSnack(context, 'Struk tersimpan di galeri (album AL-QOYYUM): $name');
  }

  Future<void> _share(ReceiptDoc doc) async {
    final png = await ReceiptExporter.capturePng(_boundaryKey);
    await FileService.shareBytes(png, _fileName(doc), 'image/png',
        text: 'Bukti pembayaran ${doc.clinicName} ${doc.numberLine}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.afterSave,
        title: const Text('Preview Struk (B5)', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<ReceiptDoc>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Menyiapkan struk...');
          }
          if (snapshot.hasError) return ErrorView(message: errorMessage(snapshot.error), onRetry: _reload);
          final doc = snapshot.data!;
          return Column(children: [
            Expanded(child: _preview(doc)),
            _actions(doc),
          ]);
        },
      ),
    );
  }

  Widget _preview(ReceiptDoc doc) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AspectRatio(
            aspectRatio: AppConfig.receiptWidthMm / AppConfig.receiptHeightMm,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: AppColors.navy30, blurRadius: 14, offset: Offset(0, 5))],
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(key: _boundaryKey, child: ReceiptView(doc: doc)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions(ReceiptDoc doc) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(() => _print(doc), 'Gagal mencetak. Pastikan printer tersedia lalu coba lagi.'),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(() => _download(doc), 'Gagal menyimpan PNG. Periksa izin penyimpanan lalu coba lagi.'),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download PNG'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.veryLightBlue, foregroundColor: AppColors.navy),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() => _share(doc), 'Gagal membagikan struk. Silakan coba lagi.'),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Bagikan'),
            ),
            if (widget.afterSave)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Selesai'),
              ),
          ]),
        ),
      ),
    );
  }
}
