import '../core/json.dart';
import 'transaction.dart';

class SalesPoint {
  const SalesPoint({required this.date, required this.count, required this.total});

  final DateTime date;
  final int count;
  final int total;

  factory SalesPoint.fromJson(Map<String, dynamic> j) => SalesPoint(
        date: asClinicDate(j['date']) ?? DateTime.now(),
        count: asInt(j['count']),
        total: asInt(j['total']),
      );
}

class TopItem {
  const TopItem({required this.name, required this.category, required this.quantity, required this.revenue});

  final String name;
  final String category;
  final int quantity;
  final int revenue;

  factory TopItem.fromJson(Map<String, dynamic> j) => TopItem(
        name: asStr(j['name']),
        category: asStr(j['category']),
        quantity: asInt(j['quantity']),
        revenue: asInt(j['revenue']),
      );
}

class OwnerDashboard {
  const OwnerDashboard({
    required this.todaySales,
    required this.todayCount,
    required this.monthSales,
    required this.monthActiveCount,
    required this.monthTransactionCount,
    required this.monthDeletedCount,
    required this.topItems,
    required this.chart,
    required this.recent,
    required this.deleted,
  });

  final int todaySales;
  final int todayCount;
  final int monthSales;
  final int monthActiveCount;
  final int monthTransactionCount;
  final int monthDeletedCount;
  final List<TopItem> topItems;
  final List<SalesPoint> chart;
  final List<TransactionModel> recent;
  final List<TransactionModel> deleted;

  factory OwnerDashboard.fromJson(Map<String, dynamic> j) => OwnerDashboard(
        todaySales: asInt(j['today_sales']),
        todayCount: asInt(j['today_count']),
        monthSales: asInt(j['month_sales']),
        monthActiveCount: asInt(j['month_active_count']),
        monthTransactionCount: asInt(j['month_transaction_count']),
        monthDeletedCount: asInt(j['month_deleted_count']),
        topItems: asList(j['top_items']).map((e) => TopItem.fromJson(asMap(e))).toList(),
        chart: asList(j['chart']).map((e) => SalesPoint.fromJson(asMap(e))).toList(),
        recent: asList(j['recent']).map((e) => TransactionModel.fromJson(asMap(e))).toList(),
        deleted: asList(j['deleted']).map((e) => TransactionModel.fromJson(asMap(e))).toList(),
      );
}

class CashierDashboard {
  const CashierDashboard({required this.todayCount, required this.todayTotal});

  final int todayCount;
  final int todayTotal;

  factory CashierDashboard.fromJson(Map<String, dynamic> j) =>
      CashierDashboard(todayCount: asInt(j['today_count']), todayTotal: asInt(j['today_total']));
}

class NamedTotal {
  const NamedTotal({required this.name, required this.total, required this.count});

  final String name;
  final int total;
  final int count;
}

class ReportSummary {
  const ReportSummary({
    required this.from,
    required this.to,
    required this.totalSales,
    required this.transactionCount,
    required this.deletedCount,
    required this.totalPayment,
    required this.totalChange,
    required this.average,
    required this.topItems,
    required this.daily,
    required this.byCategory,
    required this.byMethod,
  });

  final String from;
  final String to;
  final int totalSales;
  final int transactionCount;
  final int deletedCount;
  final int totalPayment;
  final int totalChange;
  final int average;
  final List<TopItem> topItems;
  final List<SalesPoint> daily;
  final List<NamedTotal> byCategory;
  final List<NamedTotal> byMethod;

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
        from: asStr(j['from']),
        to: asStr(j['to']),
        totalSales: asInt(j['total_sales']),
        transactionCount: asInt(j['transaction_count']),
        deletedCount: asInt(j['deleted_count']),
        totalPayment: asInt(j['total_payment']),
        totalChange: asInt(j['total_change']),
        average: asInt(j['average']),
        topItems: asList(j['top_items']).map((e) => TopItem.fromJson(asMap(e))).toList(),
        daily: asList(j['daily']).map((e) => SalesPoint.fromJson(asMap(e))).toList(),
        byCategory: asList(j['by_category'])
            .map((e) => NamedTotal(name: asStr(asMap(e)['category']), total: asInt(asMap(e)['total']), count: 0))
            .toList(),
        byMethod: asList(j['by_payment_method'])
            .map((e) => NamedTotal(
                name: asStr(asMap(e)['method']), total: asInt(asMap(e)['total']), count: asInt(asMap(e)['count'])))
            .toList(),
      );
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.username,
    required this.action,
    required this.entity,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String action;
  final String entity;
  final String description;
  final DateTime? createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id: asInt(j['id']),
        username: asStr(j['username'], '-'),
        action: asStr(j['action']),
        entity: asStr(j['entity']),
        description: asStr(j['description']),
        createdAt: asClinicDate(j['created_at']),
      );
}
