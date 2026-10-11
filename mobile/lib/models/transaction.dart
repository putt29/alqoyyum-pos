import '../core/json.dart';

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.productName,
    required this.categoryName,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final int id;
  final String productName;
  final String categoryName;
  final String? unit;
  final int price;
  final int quantity;
  final int subtotal;

  factory TransactionItem.fromJson(Map<String, dynamic> j) => TransactionItem(
        id: asInt(j['id']),
        productName: asStr(j['product_name']),
        categoryName: asStr(j['category_name']),
        unit: asStrOrNull(j['unit']),
        price: asInt(j['price']),
        quantity: asInt(j['quantity']),
        subtotal: asInt(j['subtotal']),
      );
}

/// Dipakai untuk ringkasan (daftar) maupun detail (dengan items).
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.number,
    required this.date,
    required this.patientName,
    required this.cashierName,
    required this.doctorName,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.payment,
    required this.change,
    required this.status,
    required this.itemCount,
    required this.deletedAt,
    required this.deletedByName,
    required this.deletionReason,
    required this.totalWords,
    required this.items,
  });

  final int id;
  final String number;
  final DateTime? date;
  final String patientName;
  final String cashierName;
  final String doctorName;
  final String paymentMethod;
  final int subtotal;
  final int discount;
  final int total;
  final int payment;
  final int change;
  final String status;
  final int? itemCount;
  final DateTime? deletedAt;
  final String? deletedByName;
  final String? deletionReason;
  final String totalWords;
  final List<TransactionItem> items;

  bool get isDeleted => status == 'DELETED';

  factory TransactionModel.fromJson(Map<String, dynamic> j) {
    final total = asInt(j['total']);
    return TransactionModel(
      id: asInt(j['id']),
      number: asStr(j['transaction_number']),
      date: asClinicDate(j['transaction_date']),
      patientName: asStr(j['patient_name']),
      cashierName: asStr(j['cashier_name']),
      doctorName: asStr(j['doctor_name']),
      paymentMethod: asStr(j['payment_method'], 'Cash'),
      subtotal: j['subtotal'] == null ? total : asInt(j['subtotal']),
      discount: asInt(j['discount']),
      total: total,
      payment: j['payment'] == null ? total : asInt(j['payment']),
      change: asInt(j['change']),
      status: asStr(j['status'], 'COMPLETED'),
      itemCount: j['item_count'] == null ? null : asInt(j['item_count']),
      deletedAt: asClinicDate(j['deleted_at']),
      deletedByName: asStrOrNull(j['deleted_by_name']),
      deletionReason: asStrOrNull(j['deletion_reason']),
      totalWords: asStr(j['total_words']),
      items: asList(j['items']).map((e) => TransactionItem.fromJson(asMap(e))).toList(),
    );
  }
}

class TransactionPage {
  const TransactionPage({required this.total, required this.items});

  final int total;
  final List<TransactionModel> items;

  factory TransactionPage.fromJson(Map<String, dynamic> j) => TransactionPage(
        total: asInt(j['total']),
        items: asList(j['items']).map((e) => TransactionModel.fromJson(asMap(e))).toList(),
      );
}
