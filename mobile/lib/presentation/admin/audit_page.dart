import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/reports.dart';
import '../../models/transaction.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/tx_tile.dart';
import '../transactions/transaction_detail_page.dart';

/// Owner: transaksi yang dihapus (soft delete) + audit log aktivitas penting.
class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(children: const [
        Material(
          color: AppColors.cream,
          child: TabBar(
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.navy,
            tabs: [Tab(text: 'Transaksi Dihapus'), Tab(text: 'Audit Log')],
          ),
        ),
        Expanded(child: TabBarView(children: [_DeletedTab(), _LogsTab()])),
      ]),
    );
  }
}

class _DeletedTab extends StatefulWidget {
  const _DeletedTab();

  @override
  State<_DeletedTab> createState() => _DeletedTabState();
}

class _DeletedTabState extends State<_DeletedTab> {
  int _version = 0;

  Future<void> _open(TransactionModel tx) async {
    await openTransaction(context, tx.id);
    if (mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: 900,
      child: AsyncView<TransactionPage>(
        loader: () => context.read<TransactionRepository>().list(status: 'DELETED', limit: 100),
        version: _version,
        emptyMessage: 'Belum ada transaksi yang dihapus.',
        emptyIcon: Icons.delete_outline,
        isEmpty: (page) => page.items.isEmpty,
        builder: (context, page) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: page.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final tx = page.items[i];
            return TxTile(tx: tx, showCashier: true, showDeletionInfo: true, onTap: () => _open(tx));
          },
        ),
      ),
    );
  }
}

class _LogsTab extends StatefulWidget {
  const _LogsTab();

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _version = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static IconData _icon(String action) {
    switch (action) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'LOGIN_FAILED':
        return Icons.warning_amber_outlined;
      case 'CREATE_TRANSACTION':
        return Icons.receipt_long_outlined;
      case 'DELETE_TRANSACTION':
        return Icons.delete_outline;
      case 'RESTORE_TRANSACTION':
        return Icons.restore;
      case 'UPDATE_PRICE':
        return Icons.price_change_outlined;
      case 'CREATE_PRODUCT':
      case 'UPDATE_PRODUCT':
        return Icons.medication_outlined;
      case 'CREATE_USER':
      case 'UPDATE_USER':
      case 'SEED_USER':
        return Icons.person_outline;
      case 'CHANGE_PASSWORD':
        return Icons.vpn_key_outlined;
      default:
        return Icons.settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: 900,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() {
              _query = v;
              _version++;
            }),
            decoration: appInput(null, hint: 'Cari aktivitas / pengguna...', prefix: const Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: AsyncView<AuditLogPage>(
            loader: () => context.read<AdminRepository>().auditLogs(q: _query, limit: 100),
            version: _version,
            emptyMessage: 'Belum ada aktivitas.',
            isEmpty: (page) => page.items.isEmpty,
            builder: (context, page) => ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: page.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _logTile(page.items[i]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _logTile(AuditLog log) {
    final danger = log.action == 'DELETE_TRANSACTION' || log.action == 'LOGIN_FAILED';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(_icon(log.action), color: danger ? AppColors.danger : AppColors.navy, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(log.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text('${log.username} · ${log.action} · ${dateTimeShort(log.createdAt)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }
}
