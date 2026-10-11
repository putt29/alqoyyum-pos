import 'dart:convert';

import 'package:alqoyyum_pos/core/format.dart';
import 'package:alqoyyum_pos/models/catalog.dart';
import 'package:alqoyyum_pos/models/receipt.dart';
import 'package:alqoyyum_pos/state/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contoh respons GET /api/transactions/{id}/receipt (isi struk mengikuti kwitansi Excel).
const String _receiptJson = r'''{
 "paper": {
  "name": "B5",
  "width_mm": 176,
  "height_mm": 250
 },
 "clinic": {
  "name": "AL-QOYYUM ROYAL CLINIC",
  "address": "Jl. Buana Indah No.61 Cihideung-Sadang-Purwakarta",
  "sipd_line": "No. SIPD : 446/SIPD-1785/DPMPTSP/2022",
  "phone_line": "Telp : (0264)8464554 / 0813.1314.8633 (WA)"
 },
 "title": "BUKTI PEMBAYARAN",
 "number_line": "NO : 368/1026",
 "date_text": "09 Oktober 2026",
 "received_from": {
  "label": "Diterima dari",
  "title": "Ny.",
  "name": "Yayuk Novita Dewi"
 },
 "patient": {
  "label": "Nama Pasien",
  "title": "Ny.",
  "name": "Yayuk Novita Dewi"
 },
 "doctor": {
  "label": "Nama Dokter",
  "title": "dr.",
  "name": "Maulia Mardini, SpOG, MARS"
 },
 "for_payment_label": "Untuk Pembayaran",
 "groups": [
  {
   "label": "Jasa",
   "lines": [
    {
     "name": "Konsultasi Dokter",
     "qty": null,
     "unit": null,
     "amount": 120000,
     "amount_text": "120.000,00"
    },
    {
     "name": "USG 2D",
     "qty": null,
     "unit": null,
     "amount": 80000,
     "amount_text": "80.000,00"
    },
    {
     "name": "Irigasi Vagina",
     "qty": null,
     "unit": null,
     "amount": 275000,
     "amount_text": "275.000,00"
    }
   ]
  },
  {
   "label": "Obat",
   "lines": [
    {
     "name": "Kalnex",
     "qty": 10,
     "unit": "pcs",
     "amount": 75000,
     "amount_text": "75.000,00"
    },
    {
     "name": "Zoltin",
     "qty": 5,
     "unit": "pcs",
     "amount": 125000,
     "amount_text": "125.000,00"
    },
    {
     "name": "Cefixime",
     "qty": 6,
     "unit": "pcs",
     "amount": 42000,
     "amount_text": "42.000,00"
    }
   ]
  },
  {
   "label": "BHP",
   "lines": [
    {
     "name": "Kasa",
     "qty": 1,
     "unit": "pcs",
     "amount": 10000,
     "amount_text": "10.000,00"
    },
    {
     "name": "Underpads",
     "qty": 1,
     "unit": "pcs",
     "amount": 10000,
     "amount_text": "10.000,00"
    },
    {
     "name": "Pembalut",
     "qty": 1,
     "unit": "pcs",
     "amount": 2000,
     "amount_text": "2.000,00"
    }
   ]
  }
 ],
 "line_count": 9,
 "underline_last": true,
 "currency": "Rp",
 "total_label": "Total Pembayaran",
 "total": 739000,
 "total_text": "739.000,00",
 "payment_method_label": "Cara Pembayaran",
 "payment_method": "Cash",
 "words_label": "Terbilang",
 "words": "Tujuhratus Tigapuluh Sembilan Ribu Rupiah",
 "signature": {
  "label": "Diterima oleh:",
  "name": "Nunung Nurjanah"
 },
 "payment": 739000,
 "change": 0,
 "status": "COMPLETED",
 "stamp": null
}''';

Product _product(int id, String name, int price, {String? unit = 'pcs', bool editable = false}) => Product(
      id: id,
      name: name,
      categoryId: 1,
      categoryName: 'Obat',
      unit: unit,
      costPrice: null,
      salePrice: price,
      priceEditable: editable,
      iconName: 'medicine/tablet',
      isActive: true,
    );

void main() {
  test('format Rupiah, angka, dan nama file', () {
    expect(rp(125000), 'Rp125.000');
    expect(parseDigits('Rp 125.000'), 125000);
    expect(parseDigits(''), 0);
    expect(safeFileName('Struk_367/1026'), 'Struk_367-1026');
  });

  test('keranjang: total, kembalian, dan aturan pembayaran', () {
    final cart = CartController();
    cart.add(_product(1, 'Kalnex', 7500));
    cart.add(_product(1, 'Kalnex', 7500)); // quantity jadi 2
    cart.add(_product(2, 'Konsultasi Dokter', 120000, unit: null));
    expect(cart.total, 135000);
    expect(cart.quantityOf(1), 2);

    cart.setPatientName('Siti Aminah');
    cart.setPayment(100000);
    expect(cart.paymentEnough, isFalse); // pembayaran kurang
    expect(cart.canSubmit, isFalse);

    cart.setPayment(150000);
    expect(cart.change, 15000);
    expect(cart.canSubmit, isTrue);

    cart.setPaymentMethod('Transfer'); // non-tunai: pembayaran = total
    expect(cart.effectivePayment, 135000);
    expect(cart.change, 0);

    cart.decrement(1);
    cart.decrement(1);
    expect(cart.contains(1), isFalse);
    cart.clear();
    expect(cart.isEmpty, isTrue);
  });

  test('item harga bebas memakai harga yang diisi kasir', () {
    final cart = CartController();
    cart.add(_product(9, 'Tindakan Kuretasi', 2100000, unit: null, editable: true), unitPrice: 1730000);
    expect(cart.total, 1730000);
  });

  test('ReceiptDoc membaca JSON struk dari server', () {
    final doc = ReceiptDoc.fromJson(jsonDecode(_receiptJson) as Map<String, dynamic>);
    expect(doc.clinicName, 'AL-QOYYUM ROYAL CLINIC');
    expect(doc.title, 'BUKTI PEMBAYARAN');
    expect(doc.numberLine, 'NO : 368/1026');
    expect(doc.dateText, '09 Oktober 2026');
    expect(doc.patient.title, 'Ny.');
    expect(doc.doctor.name, 'Maulia Mardini, SpOG, MARS');
    expect(doc.groups.first.label, 'Jasa');
    expect(doc.groups.first.lines.first.amountText, '120.000,00');
    expect(doc.totalText, '739.000,00');
    expect(doc.words, 'Tujuhratus Tigapuluh Sembilan Ribu Rupiah');
    expect(doc.signatureName, 'Nunung Nurjanah');
  });
}
