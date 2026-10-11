import 'package:flutter/material.dart';

import '../models/receipt.dart';

/// TEMPLATE STRUK B5 PORTRAIT (176 x 250 mm) - SATU sumber untuk preview, print, dan PNG.
///
/// Tata letak mengikuti kwitansi Excel (sheet "KWITANSI ..."): kolom A..G, judul "BUKTI PEMBAYARAN",
/// garis ganda di bawah header, label kategori dengan titik dua di tepi kolom A, kolom "Rp" + nominal
/// (format akuntansi), "Total Pembayaran", "Cara Pembayaran", "Terbilang", dan "Diterima oleh:".
/// Kanvas logis 704 x 1000 (4 px per mm). Isi yang terlalu panjang otomatis diperkecil (FittedBox).
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key, required this.doc});

  final ReceiptDoc doc;

  static const double canvasW = 704;
  static const double canvasH = 1000;
  static const double _marginX = 32;
  static const double _marginTop = 34;
  static const double _marginBottom = 30;
  static const double _contentW = canvasW - 2 * _marginX;

  /// Skala dari satuan Excel (pt / px kolom) ke kanvas.
  static const double _pt = 1.229;
  static const double _s = _contentW / 694;

  // Lebar kolom Excel A..G (px) yang diskalakan.
  static const double _colA = 85 * _s;
  static const double _colB = 64 * _s;
  static const double _colC = 47 * _s;
  static const double _colD = 64 * _s;
  static const double _colE = 64 * _s;
  static const double _colF = 215 * _s;
  static const double _colG = 155 * _s;
  static const double _rowH = 15.75 * _pt;

  static TextStyle _t(double pt, {bool bold = false}) => TextStyle(
        fontFamily: 'Carlito',
        fontSize: pt * _pt,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: Colors.black,
        height: 1.12,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      );

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: _t(11),
        child: Container(
          width: canvasW,
          height: canvasH,
          color: Colors.white,
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_marginX, _marginTop, _marginX, _marginBottom),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: _contentW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _content(),
                  ),
                ),
              ),
            ),
            if (doc.stamp != null) Positioned.fill(child: IgnorePointer(child: Center(child: _stamp(doc.stamp!)))),
          ]),
        ),
      ),
    );
  }

  Widget _stamp(String text) {
    const c = Color(0x99C62828);
    return Transform.rotate(
      angle: -0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: c, width: 4), borderRadius: BorderRadius.circular(8)),
        child: const Text('DIHAPUS OLEH OWNER',
            style: TextStyle(
                fontFamily: 'Carlito',
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: c,
                decoration: TextDecoration.none)),
      ),
    );
  }

  List<Widget> _content() {
    final out = <Widget>[
      _header(),
      _doubleRule(),
      Center(child: Text(doc.title, style: _t(14, bold: true))),
      Center(child: Text(doc.numberLine, style: _t(12))),
      const SizedBox(height: 4.5 * _pt),
      _fieldRow(doc.receivedFrom, trailing: doc.dateText),
      _fieldRow(doc.patient),
      _fieldRow(doc.doctor),
      SizedBox(height: _rowH, child: Align(alignment: Alignment.centerLeft, child: Text(doc.forPaymentLabel, style: _t(12)))),
    ];

    final totalLines = doc.groups.fold<int>(0, (s, g) => s + g.lines.length);
    var index = 0;
    for (final group in doc.groups) {
      for (var i = 0; i < group.lines.length; i++) {
        index++;
        out.add(_itemRow(
          group.lines[i],
          groupLabel: i == 0 ? group.label : null,
          underline: doc.underlineLast && index == totalLines,
        ));
      }
    }

    out.addAll([
      const SizedBox(height: _rowH),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _rowH),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(doc.totalLabel, style: _t(12, bold: true))),
          SizedBox(width: _colG, child: _amountCell(doc.totalText, 12, bold: true)),
        ]),
      ),
      const SizedBox(height: _rowH),
      _kvRow(doc.paymentMethodLabel, doc.paymentMethod),
      _kvRow(doc.wordsLabel, doc.words, boldValue: true),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(width: _colA + _colB + _colC + _colD + _colE + _colF),
        SizedBox(
          width: _colG,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.signatureLabel, style: _t(12)),
            const SizedBox(height: 3 * _rowH),
            Text(doc.signatureName, style: _t(12)),
          ]),
        ),
      ]),
    ]);
    return out;
  }

  Widget _header() {
    return SizedBox(
      height: 74,
      child: Stack(children: [
        Positioned(
          left: 10,
          top: 4,
          child: Image.asset('assets/images/logo_mark.png', height: 64, fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(doc.clinicName, style: _t(14, bold: true)),
            Text(doc.address, style: _t(10.5)),
            if (doc.sipdLine.isNotEmpty) Text(doc.sipdLine, style: _t(10.5)),
            Text(doc.phoneLine, style: _t(10.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _doubleRule() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 1.4, color: Colors.black),
        const SizedBox(height: 2),
        Container(height: 1.4, color: Colors.black),
      ]),
    );
  }

  /// "Diterima dari  : Ny. Nama ........ 09 Oktober 2026"
  Widget _fieldRow(ReceiptParty p, {String? trailing}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowH),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: _colA + _colB, child: Text(p.label, style: _t(12))),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _colC),
          child: Text(': ${p.title}', style: _t(12), softWrap: false),
        ),
        Expanded(child: Text(p.name, style: _t(12), maxLines: 2, overflow: TextOverflow.ellipsis)),
        if (trailing != null) Text(trailing, style: _t(12)),
      ]),
    );
  }

  /// "Cara Pembayaran  :  Cash"
  Widget _kvRow(String label, String value, {bool boldValue = false}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowH),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: _colA + _colB, child: Text(label, style: _t(12))),
        SizedBox(width: _colC, child: Center(child: Text(':', style: _t(12, bold: true)))),
        Expanded(child: Text(value, style: _t(12, bold: boldValue))),
      ]),
    );
  }

  /// Satu baris item. Label kategori + ":" (di tepi kolom A) hanya pada baris pertama grup.
  Widget _itemRow(ReceiptLine line, {String? groupLabel, required bool underline}) {
    final hasQty = line.qty != null;
    final nameWidth = hasQty ? _colB + _colC + _colD : _colB + _colC + _colD + _colE + _colF;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowH),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: _colA,
          child: groupLabel == null
              ? null
              : Row(children: [Text(groupLabel, style: _t(11)), const Spacer(), Text(':', style: _t(11))]),
        ),
        SizedBox(
          width: nameWidth,
          child: Padding(padding: const EdgeInsets.only(left: 4), child: Text(line.name, style: _t(11))),
        ),
        if (hasQty) ...[
          SizedBox(width: _colE, child: Text('${line.qty}', textAlign: TextAlign.right, style: _t(11))),
          SizedBox(
            width: _colF,
            child: Padding(padding: const EdgeInsets.only(left: 4), child: Text(line.unit ?? '', style: _t(11))),
          ),
        ],
        SizedBox(width: _colG, child: _amountCell(line.amountText, 11, underline: underline)),
      ]),
    );
  }

  /// Format akuntansi Excel: "Rp" rata kiri, nominal rata kanan.
  Widget _amountCell(String text, double pt, {bool bold = false, bool underline = false}) {
    final style = _t(pt, bold: bold);
    return Container(
      decoration: underline ? const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 1))) : null,
      child: Row(children: [Text(doc.currency, style: style), const Spacer(), Text(text, style: style)]),
    );
  }
}
