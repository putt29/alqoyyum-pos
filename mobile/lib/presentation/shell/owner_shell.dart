import 'package:flutter/material.dart';

import '../admin/audit_page.dart';
import '../admin/cashiers_page.dart';
import '../admin/settings_page.dart';
import '../dashboard/owner_dashboard_page.dart';
import '../pos/open_pos.dart';
import '../products/products_page.dart';
import '../reports/reports_page.dart';
import '../transactions/transactions_page.dart';
import 'app_shell.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      bottomBarOnPhone: false,
      items: [
        NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, page: (_) => const OwnerDashboardPage()),
        NavItem(label: 'Transaksi Baru', icon: Icons.add_shopping_cart, action: openPos),
        NavItem(label: 'Transaksi', icon: Icons.receipt_long_outlined, page: (_) => const TransactionsPage(owner: true)),
        NavItem(label: 'Produk', icon: Icons.medication_outlined, page: (_) => const ProductsPage(owner: true)),
        NavItem(label: 'Laporan', icon: Icons.bar_chart_outlined, page: (_) => const ReportsPage()),
        NavItem(label: 'Transaksi Dihapus / Audit', icon: Icons.fact_check_outlined, page: (_) => const AuditPage()),
        NavItem(label: 'Kasir', icon: Icons.groups_outlined, page: (_) => const CashiersPage()),
        NavItem(label: 'Pengaturan', icon: Icons.settings_outlined, page: (_) => const SettingsPage()),
      ],
    );
  }
}
