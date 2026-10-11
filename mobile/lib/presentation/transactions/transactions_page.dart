import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/tx_tile.dart';
import 'transaction_detail_page.dart';

enum _Range { today, week, month, all, custom }

/// Riwayat transaksi. Owner: semua kasir + filter status. Kasir: hanya transaksi miliknya yang aktif.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.owner});

  final bool owner;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const int _pageSize = 40;

  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  _Range _range = _Range.today;
  DateTimeRange? _custom;
  String _status = 'COMPLETED';
  String _query = '';

  final List<TransactionModel> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  DateTime? get _from {
    final now = DateTime.now();
    switch (_range) {
      case _Range.today:
        return DateTime(now.year, now.month, now.day);
      case _Range.week:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case _Range.month:
        return DateTime(now.year, now.month, 1);
      case _Range.all:
        return null;
      case _Range.custom:
        return _custom?.start;
    }
  }

  DateTime? get _to {
    final now = DateTime.now();
    switch (_range) {
      case _Range.all:
        return null;
      case _Range.custom:
        return _custom?.end;
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> _load({required bool reset}) async {
    final repo = context.read<TransactionRepository>();
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await repo.list(
        q: _query,
        status: widget.owner ? _status : 'COMPLETED',
        from: _from,
        to: _to,
        limit: _pageSize,
        offset: reset ? 0 : _items.length,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _total = page.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value;
      _load(reset: true);
    });
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _custom,
      helpText: 'Pilih rentang tanggal',
    );
    if (picked == null) return;
    setState(() {
      _custom = picked;
      _range = _Range.custom;
    });
    _load(reset: true);
  }

  void _setRange(_Range r) {
    setState(() => _range = r);
    _load(reset: true);
  }

  Future<void> _open(TransactionModel tx) async {
    await openTransaction(context, tx.id);
    if (mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: 900,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: appInput(null, hint: 'Cari nama pasien / nomor...', prefix: const Icon(Icons.search)),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            _chip('Hari ini', _Range.today),
            _chip('7 hari', _Range.week),
            _chip('Bulan ini', _Range.month),
            _chip('Semua', _Range.all),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: PillChip(
                label: _range == _Range.custom && _custom != null
                    ? '${dayMonth(_custom!.start)} - ${dayMonth(_custom!.end)}'
                    : 'Pilih tanggal',
                selected: _range == _Range.custom,
                onTap: _pickCustom,
              ),
            ),
          ]),
        ),
        if (widget.owner)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.navy,
                selectedForegroundColor: Colors.white,
                foregroundColor: AppColors.navy,
              ),
              segments: const [
                ButtonSegment<String>(value: 'COMPLETED', label: Text('Aktif')),
                ButtonSegment<String>(value: 'DELETED', label: Text('Dihapus')),
                ButtonSegment<String>(value: 'ALL', label: Text('Semua')),
              ],
              selected: {_status},
              onSelectionChanged: (s) {
                setState(() => _status = s.first);
                _load(reset: true);
              },
            ),
          ),
        const SizedBox(height: 8),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _chip(String label, _Range r) => Padding(
        padding: EdgeInsets.only(right: r == _Range.all ? 0 : 8),
        child: PillChip(label: label, selected: _range == r, onTap: () => _setRange(r)),
      );

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) return const EmptyView(message: 'Belum ada transaksi.', icon: Icons.receipt_long_outlined);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _items.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          if (_items.length >= _total) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('$_total transaksi', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            );
          }
          return Center(
            child: _loadingMore
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.navy))
                : TextButton(onPressed: () => _load(reset: false), child: const Text('Muat lebih banyak')),
          );
        }
        final tx = _items[i];
        return TxTile(tx: tx, showCashier: widget.owner, onTap: () => _open(tx));
      },
    );
  }
}
