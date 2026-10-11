import '../core/format.dart';
import '../core/json.dart';
import '../models/cart_line.dart';
import '../models/receipt.dart';
import '../models/transaction.dart';
import '../services/api_client.dart';


class TransactionRepository {
  TransactionRepository(this._api);

  final ApiClient _api;

  Future<TransactionModel> create({
    required String patientName,
    required List<CartLine> lines,
    required String paymentMethod,
    required int payment,
  }) async {
    final body = <String, dynamic>{
      'patient_name': patientName,
      'payment_method': paymentMethod,
      'payment': payment,
      'items': lines
          .map((l) => <String, dynamic>{
                'product_id': l.product.id,
                'quantity': l.quantity,
                if (l.product.priceEditable) 'unit_price': l.unitPrice,
              })
          .toList(),
    };
    return TransactionModel.fromJson(asMap(await _api.post('/api/transactions', body: body)));
  }

  Future<TransactionPage> list({
    String q = '',
    String status = 'COMPLETED',
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get('/api/transactions', query: {
      'q': q,
      'status': status,
      'from_date': from == null ? null : isoDate(from),
      'to_date': to == null ? null : isoDate(to),
      'limit': limit,
      'offset': offset,
    });
    return TransactionPage.fromJson(asMap(data));
  }

  Future<TransactionModel> detail(int id) async =>
      TransactionModel.fromJson(asMap(await _api.get('/api/transactions/$id')));

  Future<ReceiptDoc> receipt(int id) async =>
      ReceiptDoc.fromJson(asMap(await _api.get('/api/transactions/$id/receipt')));

  Future<TransactionModel> delete(int id, String reason) async =>
      TransactionModel.fromJson(asMap(await _api.post('/api/transactions/$id/delete', body: {'reason': reason})));

  Future<TransactionModel> restore(int id) async =>
      TransactionModel.fromJson(asMap(await _api.post('/api/transactions/$id/restore')));

  Future<String> nextNumber() async => asStr(asMap(await _api.get('/api/transactions/next-number'))['number']);
}
