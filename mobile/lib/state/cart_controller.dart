import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../models/cart_line.dart';
import '../models/catalog.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Keranjang transaksi baru: nama pasien diketik kasir, item, quantity, pembayaran.
class CartController extends ChangeNotifier {
  final Map<int, CartLine> _lines = <int, CartLine>{};

  String patientName = '';
  String paymentMethod = 'Cash';
  int payment = 0;
  bool submitting = false;
  String? submitError;

  List<CartLine> get lines => _lines.values.toList();
  int get itemCount => _lines.length;
  int get totalQuantity => _lines.values.fold<int>(0, (s, l) => s + l.quantity);
  int get total => _lines.values.fold<int>(0, (s, l) => s + l.subtotal);
  bool get isEmpty => _lines.isEmpty;
  bool get isFull => _lines.length >= AppConfig.maxItems;

  /// Non-tunai: pembayaran otomatis = total.
  int get effectivePayment => paymentMethod == 'Cash' ? payment : total;
  int get change => effectivePayment - total;
  bool get paymentEnough => total > 0 && effectivePayment >= total;
  bool get patientValid => patientName.trim().length >= 2;
  bool get canSubmit => !submitting && !isEmpty && patientValid && paymentEnough;

  int quantityOf(int productId) => _lines[productId]?.quantity ?? 0;
  bool contains(int productId) => _lines.containsKey(productId);

  /// Tambah +1 (atau buat baris baru). Mengembalikan false bila keranjang penuh.
  bool add(Product p, {int? unitPrice}) {
    final line = _lines[p.id];
    if (line == null) {
      if (isFull) return false;
      _lines[p.id] = CartLine(p, unitPrice: unitPrice);
    } else {
      line.quantity += 1;
      if (unitPrice != null) line.unitPrice = unitPrice;
    }
    notifyListeners();
    return true;
  }

  void setQuantity(int productId, int quantity) {
    final line = _lines[productId];
    if (line == null) return;
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      line.quantity = quantity > 9999 ? 9999 : quantity;
    }
    notifyListeners();
  }

  void increment(int productId) => setQuantity(productId, quantityOf(productId) + 1);
  void decrement(int productId) => setQuantity(productId, quantityOf(productId) - 1);

  void setUnitPrice(int productId, int price) {
    final line = _lines[productId];
    if (line == null) return;
    line.unitPrice = price;
    notifyListeners();
  }

  void remove(int productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  void setPatientName(String value) {
    patientName = value;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  void setPayment(int value) {
    payment = value;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    patientName = '';
    paymentMethod = 'Cash';
    payment = 0;
    submitting = false;
    submitError = null;
    notifyListeners();
  }

  Future<TransactionModel?> submit(TransactionRepository repo) async {
    if (!canSubmit) return null;
    submitting = true;
    submitError = null;
    notifyListeners();
    try {
      final tx = await repo.create(
        patientName: patientName.trim(),
        lines: lines,
        paymentMethod: paymentMethod,
        payment: effectivePayment,
      );
      submitting = false;
      notifyListeners();
      return tx;
    } catch (e) {
      submitting = false;
      submitError = errorMessage(e);
      notifyListeners();
      return null;
    }
  }
}
