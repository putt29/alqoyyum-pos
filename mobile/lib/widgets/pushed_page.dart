import 'package:flutter/material.dart';

import '../core/colors.dart';

/// Pembungkus halaman yang dibuka layar penuh (dengan tombol kembali).
class PushedPage extends StatelessWidget {
  const PushedPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: child,
    );
  }
}
