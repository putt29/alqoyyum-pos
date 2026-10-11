import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../models/reports.dart';
import '../../repositories/report_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/sales_chart.dart';
import '../../widgets/tx_tile.dart';
import '../pos/open_pos.dart';
import '../transactions/transaction_detail_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _version = 0;

  void _refresh() => setState(() => _version++);

  Future<void> _openTx(int id) async {
    await openTransaction(context, id);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<OwnerDashboard>(
      loader: () => context.read<ReportRepository>().ownerDashboard(),
      version: _version,
      builder: (context, d) => ListView(padding: const EdgeInsets.all(16), children: [
        ContentWidth(child: _content(d)),
      ]),
    );
  }

  Widget _content(OwnerDashboard d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      whiteCard(
        child: Row(children: [
          const AppLogo(height: 64),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppConfig.clinicName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
              SizedBox(height: 2),
              Text('Dashboard Owner', style: TextStyle(color: AppColors.muted)),
            ]),
          ),
          IconButton(tooltip: 'Muat ulang', onPressed: _refresh, icon: const Icon(Icons.refresh, color: AppColors.navy)),
        ]),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () async {
          await openPos(context);
          if (mounted) _refresh();
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Transaksi Baru'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 760 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: w,
              child: StatCard(
                  title: 'Penjualan hari ini',
                  value: rp(d.todaySales),
                  icon: Icons.today_outlined,
                  subtitle: '${d.todayCount} transaksi')),
          SizedBox(
              width: w,
              child: StatCard(
                  title: 'Penjualan bulan ini',
                  value: rp(d.monthSales),
                  icon: Icons.calendar_month_outlined,
                  subtitle: '${d.monthActiveCount} transaksi aktif')),
          SizedBox(
              width: w,
              child: StatCard(
                  title: 'Jumlah transaksi (bulan ini)',
                  value: '${d.monthTransactionCount}',
                  icon: Icons.receipt_long_outlined,
                  subtitle: '${d.monthDeletedCount} dihapus')),
          SizedBox(
              width: w,
              child: StatCard(
                  title: 'Transaksi aktif (bulan ini)', value: '${d.monthActiveCount}', icon: Icons.verified_outlined)),
        ]);
      }),
      const SectionTitle('Grafik penjualan 14 hari terakhir'),
      whiteCard(child: SalesBarChart(points: d.chart)),
      const SectionTitle('Item terlaris bulan ini'),
      whiteCard(
        child: d.topItems.isEmpty
            ? const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada penjualan.', style: TextStyle(color: AppColors.muted)))
            : Column(children: [
                for (var i = 0; i < d.topItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.veryLightBlue,
                        child: Text('${i + 1}', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d.topItems[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('${d.topItems[i].quantity}x', style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(width: 10),
                      Text(rp(d.topItems[i].revenue), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                    ]),
                  ),
              ]),
      ),
      const SectionTitle('Transaksi terbaru'),
      if (d.recent.isEmpty)
        whiteCard(child: const Text('Belum ada transaksi.', style: TextStyle(color: AppColors.muted)))
      else
        for (final tx in d.recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TxTile(tx: tx, showCashier: true, onTap: () => _openTx(tx.id)),
          ),
      const SectionTitle('Deleted Transactions / Audit'),
      if (d.deleted.isEmpty)
        whiteCard(child: const Text('Tidak ada transaksi yang dihapus.', style: TextStyle(color: AppColors.muted)))
      else
        for (final tx in d.deleted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TxTile(tx: tx, showCashier: true, showDeletionInfo: true, onTap: () => _openTx(tx.id)),
          ),
    ]);
  }
}
