import 'package:flutter/material.dart';

import 'pos_page.dart';

/// Membuka layar Transaksi Baru (layar penuh agar area produk & keranjang lega).
Future<void> openPos(BuildContext context) {
  return Navigator.of(context).push<void>(MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/pos'),
    builder: (_) => const PosPage(),
  ));
}
