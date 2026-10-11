import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/transaction.dart';
import 'common.dart';

/// Baris ringkas satu transaksi (dashboard, riwayat, audit).
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, required this.onTap, this.showCashier = false, this.showDeletionInfo = false});

  final TransactionModel tx;
  final VoidCallback onTap;
  final bool showCashier;
  final bool showDeletionInfo;

  @override
  Widget build(BuildContext context) {
    final deleted = tx.isDeleted;
    return Material(
      color: deleted ? AppColors.dangerBg : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: deleted ? AppColors.danger.withAlpha(60) : AppColors.line),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: deleted ? Colors.white : AppColors.veryLightBlue, borderRadius: BorderRadius.circular(12)),
              child: Icon(deleted ? Icons.delete_outline : Icons.receipt_long_outlined,
                  color: deleted ? AppColors.danger : AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  'NO ${tx.number} · ${dateTimeShort(tx.date)}${showCashier ? ' · ${tx.cashierName}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (deleted) ...[
                  const SizedBox(height: 4),
                  const StatusPill(text: 'DIHAPUS OLEH OWNER', danger: true),
                  if (showDeletionInfo)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Dihapus oleh ${tx.deletedByName ?? 'Owner'} · ${dateTimeShort(tx.deletedAt)}\nAlasan: ${tx.deletionReason ?? '-'}',
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Text(rp(tx.total),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: deleted ? AppColors.danger : AppColors.navy,
                    decoration: deleted ? TextDecoration.lineThrough : null)),
          ]),
        ),
      ),
    );
  }
}

/// Dekorasi kartu putih standar.
Widget whiteCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) =>
    Container(padding: padding, decoration: cardDecoration(), child: child);
