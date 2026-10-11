import 'package:flutter/material.dart';

import '../admin/settings_page.dart';
import '../dashboard/cashier_dashboard_page.dart';
import '../pos/open_pos.dart';
import '../products/products_page.dart';
import '../transactions/transactions_page.dart';
import 'app_shell.dart';

class CashierShell extends StatelessWidget {
  const CashierShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      bottomBarOnPhone: true,
      items: [
        NavItem(label: 'Dashboard', icon: Icons.home_outlined, page: (_) => const CashierDashboardPage()),
        NavItem(label: 'Transaksi Baru', icon: Icons.add_circle_outline, action: openPos),
        NavItem(label: 'Produk', icon: Icons.medication_outlined, page: (_) => const ProductsPage(owner: false)),
        NavItem(label: 'Riwayat', icon: Icons.history, page: (_) => const TransactionsPage(owner: false)),
        NavItem(label: 'Profil', icon: Icons.person_outline, page: (_) => const SettingsPage()),
      ],
    );
  }
}
