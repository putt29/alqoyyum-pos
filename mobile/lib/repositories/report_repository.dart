import 'dart:typed_data';

import '../core/format.dart';
import '../core/json.dart';
import '../models/reports.dart';
import '../services/api_client.dart';

class ReportRepository {
  ReportRepository(this._api);

  final ApiClient _api;

  Future<OwnerDashboard> ownerDashboard() async =>
      OwnerDashboard.fromJson(asMap(await _api.get('/api/dashboard/owner')));

  Future<CashierDashboard> cashierDashboard() async =>
      CashierDashboard.fromJson(asMap(await _api.get('/api/dashboard/cashier')));

  Future<ReportSummary> summary(DateTime from, DateTime to) async => ReportSummary.fromJson(
      asMap(await _api.get('/api/reports/summary', query: {'from_date': isoDate(from), 'to_date': isoDate(to)})));

  /// format: 'pdf' atau 'xlsx'
  Future<Uint8List> export(String format, DateTime from, DateTime to) =>
      _api.download('/api/reports/export.$format', query: {'from_date': isoDate(from), 'to_date': isoDate(to)});
}
