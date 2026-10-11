import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/config.dart';
import 'receipt_view.dart';

/// Ekspor struk dari template yang SAMA (ReceiptView): PNG ~300 DPI dan cetak B5.
class ReceiptExporter {
  ReceiptExporter._();

  /// B5 176 x 250 mm pada 300 DPI = 2079 x 2953 px (rasio sama dengan kanvas 704 x 1000).
  static const int targetHeightPx = 2953;

  /// Tangkap [boundaryKey] (RepaintBoundary di sekitar ReceiptView) menjadi PNG tajam, bukan screenshot layar.
  static Future<Uint8List> capturePng(GlobalKey boundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      throw StateError('Struk belum siap.');
    }
    final ratio = targetHeightPx / ReceiptView.canvasH;
    final ui.Image image = await object.toImage(pixelRatio: ratio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Gagal membuat PNG.');
      return _withDpi(data.buffer.asUint8List(), 300);
    } finally {
      image.dispose();
    }
  }

  /// Cetak ke kertas 176 x 250 mm (B5). Halaman PDF = gambar struk penuh, tanpa resize ke A4.
  static Future<void> printPng(Uint8List png, String jobName) async {
    final format = PdfPageFormat(AppConfig.receiptWidthMm * PdfPageFormat.mm, AppConfig.receiptHeightMm * PdfPageFormat.mm);
    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    doc.addPage(pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) => pw.Image(image, fit: pw.BoxFit.fill),
    ));
    final bytes = await doc.save();
    await Printing.layoutPdf(
      name: jobName,
      format: format,
      dynamicLayout: false,
      onLayout: (PdfPageFormat _) async => bytes,
    );
  }

  /// Sisipkan chunk pHYs agar PNG tercatat 300 DPI (dibaca editor gambar / printer).
  static Uint8List _withDpi(Uint8List png, int dpi) {
    const headerLength = 33; // signature(8) + IHDR(25)
    if (png.length <= headerLength) return png;
    final ppm = (dpi / 0.0254).round();
    final payload = ByteData(9)
      ..setUint32(0, ppm)
      ..setUint32(4, ppm)
      ..setUint8(8, 1);
    final typeAndData = Uint8List(13);
    typeAndData.setRange(0, 4, const [0x70, 0x48, 0x59, 0x73]); // "pHYs"
    typeAndData.setRange(4, 13, payload.buffer.asUint8List());
    final length = ByteData(4)..setUint32(0, 9);
    final crc = ByteData(4)..setUint32(0, _crc32(typeAndData));
    final out = BytesBuilder();
    out.add(png.sublist(0, headerLength));
    out.add(length.buffer.asUint8List());
    out.add(typeAndData);
    out.add(crc.buffer.asUint8List());
    out.add(png.sublist(headerLength));
    return out.toBytes();
  }

  static int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc ^= b;
      for (var k = 0; k < 8; k++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
