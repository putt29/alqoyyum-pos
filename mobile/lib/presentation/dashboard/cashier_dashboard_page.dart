import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../models/reports.dart';
import '../../repositories/report_repository.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/pushed_page.dart';
import '../../widgets/tx_tile.dart';
import '../pos/open_pos.dart';
import '../products/products_page.dart';
import '../transactions/transactions_page.dart';

/// Dashboard kasir: sederhana, fokus ke tombol Transaksi Baru.
class CashierDashboardPage extends StatefulWidget {
  const CashierDashboardPage({super.key});

  @override
  State<CashierDashboardPage> createState() => _CashierDashboardPageState();
}

class _CashierDashboardPageState extends State<CashierDashboardPage> {
  int _version = 0;

  Future<void> _newTransaction() async {
    await openPos(context);
    if (mounted) setState(() => _version++);
  }

  void _push(String title, Widget child) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PushedPage(title: title, child: child)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return ListView(padding: const EdgeInsets.all(16), children: [
      ContentWidth(
        maxWidth: 720,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          whiteCard(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              const AppLogo(height: 110, full: true),
              const SizedBox(height: 8),
              const Text(AppConfig.clinicName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(height: 2),
              Text('Halo, ${user?.fullName ?? 'Kasir'}', style: const TextStyle(color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _newTransaction,
            icon: const Icon(Icons.add_circle_outline, size: 26),
            label: const Text('New Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 14),
          AsyncView<CashierDashboard>(
            loader: () => context.read<ReportRepository>().cashierDashboard(),
            version: _version,
            builder: (context, d) => Row(children: [
              Expanded(child: StatCard(title: 'Transaksi Anda hari ini', value: '${d.todayCount}', icon: Icons.receipt_long_outlined)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(title: 'Total hari ini', value: rp(d.todayTotal), icon: Icons.payments_outlined)),
            ]),
          ),
          const SectionTitle('Menu'),
          _menuTile(Icons.medication_outlined, 'Products / Services', 'Lihat obat, jasa, dan tindakan',
              () => _push('Produk & Jasa', const ProductsPage(owner: false))),
          const SizedBox(height: 8),
          _menuTile(Icons.history, 'Transaction History', 'Riwayat transaksi Anda',
              () => _push('Riwayat Transaksi', const TransactionsPage(owner: false))),
        ]),
      ),
    ]);
  }

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.veryLightBlue, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}
