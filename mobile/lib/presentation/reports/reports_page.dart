import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../models/reports.dart';
import '../../repositories/report_repository.dart';
import '../../services/file_service.dart';
import '../../widgets/common.dart';
import '../../widgets/sales_chart.dart';
import '../../widgets/tx_tile.dart';

enum _Preset { today, week, month, custom }

/// Laporan penjualan (hanya transaksi AKTIF). Ekspor PDF / Excel.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  _Preset _preset = _Preset.today;
  DateTimeRange? _custom;
  int _version = 0;
  bool _exporting = false;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _from {
    switch (_preset) {
      case _Preset.today:
        return _today;
      case _Preset.week:
        return _today.subtract(const Duration(days: 6));
      case _Preset.month:
        return DateTime(_today.year, _today.month, 1);
      case _Preset.custom:
        return _custom?.start ?? _today;
    }
  }

  DateTime get _to => _preset == _Preset.custom ? (_custom?.end ?? _today) : _today;

  void _set(_Preset p) => setState(() {
        _preset = p;
        _version++;
      });

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(_today.year + 1),
      initialDateRange: _custom,
      helpText: 'Pilih rentang tanggal laporan',
    );
    if (picked == null) return;
    setState(() {
      _custom = picked;
      _preset = _Preset.custom;
      _version++;
    });
  }

  Future<void> _export(String format) async {
    final repo = context.read<ReportRepository>();
    final from = _from;
    final to = _to;
    setState(() => _exporting = true);
    try {
      final bytes = await repo.export(format, from, to);
      final name = 'Laporan_${isoDate(from)}_${isoDate(to)}.$format';
      final mime = format == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      await FileService.shareBytes(bytes, name, mime, text: 'Laporan penjualan AL-QOYYUM ROYAL CLINIC');
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), children: [
            PillChip(label: 'Hari ini', selected: _preset == _Preset.today, onTap: () => _set(_Preset.today)),
            const SizedBox(width: 8),
            PillChip(label: 'Mingguan (7 hari)', selected: _preset == _Preset.week, onTap: () => _set(_Preset.week)),
            const SizedBox(width: 8),
            PillChip(label: 'Bulan ini', selected: _preset == _Preset.month, onTap: () => _set(_Preset.month)),
            const SizedBox(width: 8),
            PillChip(
              label: _preset == _Preset.custom && _custom != null
                  ? '${dayMonth(_custom!.start)} - ${dayMonth(_custom!.end)}'
                  : 'Rentang tanggal',
              selected: _preset == _Preset.custom,
              onTap: _pickCustom,
            ),
          ]),
        ),
        Expanded(
          child: AsyncView<ReportSummary>(
            loader: () => context.read<ReportRepository>().summary(_from, _to),
            version: _version,
            builder: (context, s) => ListView(padding: const EdgeInsets.all(12), children: [_content(s)]),
          ),
        ),
      ]),
    );
  }

  Widget _content(ReportSummary s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Periode ${dateShort(_from)} - ${dateShort(_to)}', style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 760 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(width: w, child: StatCard(title: 'Total penjualan', value: rp(s.totalSales), icon: Icons.payments_outlined)),
          SizedBox(
              width: w,
              child: StatCard(
                  title: 'Transaksi aktif',
                  value: '${s.transactionCount}',
                  icon: Icons.receipt_long_outlined,
                  subtitle: '${s.deletedCount} dihapus (tidak dihitung)')),
          SizedBox(width: w, child: StatCard(title: 'Total pembayaran', value: rp(s.totalPayment), icon: Icons.account_balance_wallet_outlined)),
          SizedBox(width: w, child: StatCard(title: 'Rata-rata / transaksi', value: rp(s.average), icon: Icons.analytics_outlined)),
        ]);
      }),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export('pdf'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ekspor PDF'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export('xlsx'),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Ekspor Excel'),
          ),
        ),
      ]),
      if (_exporting) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(color: AppColors.navy)),
      const SectionTitle('Grafik penjualan'),
      whiteCard(child: SalesBarChart(points: s.daily)),
      const SectionTitle('Item terlaris'),
      whiteCard(
        child: s.topItems.isEmpty
            ? const Text('Belum ada penjualan pada periode ini.', style: TextStyle(color: AppColors.muted))
            : Column(children: [
                for (final it in s.topItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(it.category, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ]),
                      ),
                      Text('${it.quantity}x', style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(width: 10),
                      Text(rp(it.revenue), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                    ]),
                  ),
              ]),
      ),
      if (s.byCategory.isNotEmpty) ...[
        const SectionTitle('Penjualan per kategori'),
        whiteCard(
          child: Column(children: [
            for (final c in s.byCategory)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(c.name)),
                  Text(rp(c.total), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                ]),
              ),
          ]),
        ),
      ],
      if (s.byMethod.isNotEmpty) ...[
        const SectionTitle('Cara pembayaran'),
        whiteCard(
          child: Column(children: [
            for (final m in s.byMethod)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text('${m.name} (${m.count}x)')),
                  Text(rp(m.total), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                ]),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 24),
    ]);
  }
}
