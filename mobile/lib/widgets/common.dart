import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/colors.dart';
import '../core/errors.dart';
import '../core/format.dart';
import '../core/icon_helpers.dart';
import '../core/theme.dart';

/// Logo klinik. full=true: gedung + tulisan; false: hanya gedung.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 72, this.full = false});

  final double height;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      full ? 'assets/images/logo_full.png' : 'assets/images/logo_mark.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stack) => Icon(Icons.local_hospital, size: height, color: AppColors.navy),
    );
  }
}

/// Icon item (SVG lokal). Bila icon tidak ditemukan, dipakai icon kategori.
class ItemIcon extends StatelessWidget {
  const ItemIcon({super.key, required this.iconName, required this.categoryName, this.size = 40});

  final String iconName;
  final String categoryName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = resolveIconName(iconName, categoryName);
    return SvgPicture.asset('assets/icons/$name.svg', width: size, height: size, fit: BoxFit.contain);
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.navy),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!, style: const TextStyle(color: AppColors.muted)),
        ],
      ]),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined, this.action});

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: AppColors.lightBlue),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.danger),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.navy, fontSize: 15)),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
          ],
        ]),
      ),
    );
  }
}

/// Memuat data async dengan state loading / error / empty / sukses. Ubah [version] untuk memuat ulang.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.loader,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'Belum ada data.',
    this.emptyIcon = Icons.inbox_outlined,
    this.version = 0,
  });

  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;
  final int version;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  void didUpdateWidget(covariant AsyncView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) _reload();
  }

  void _reload() {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
        if (snapshot.hasError) return ErrorView(message: errorMessage(snapshot.error), onRetry: _reload);
        final data = snapshot.data as T;
        final empty = widget.isEmpty;
        if (empty != null && empty(data)) {
          return EmptyView(message: widget.emptyMessage, icon: widget.emptyIcon);
        }
        return widget.builder(context, data);
      },
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? AppColors.danger : AppColors.navy,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: destructive ? AppColors.danger : AppColors.navy),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Input nominal Rupiah dengan pemisah ribuan saat mengetik.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final text = thousands(int.tryParse(digits) ?? 0);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Dialog isi harga (untuk item "harga bebas"). Mengembalikan null bila dibatalkan.
Future<int?> askPrice(BuildContext context, {required String name, required int initial}) {
  final controller = TextEditingController(text: initial > 0 ? thousands(initial) : '');
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Harga: $name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [ThousandsInputFormatter()],
        decoration: appInput('Harga (Rp)', hint: 'Masukkan harga'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            final v = parseDigits(controller.text);
            if (v <= 0) return;
            Navigator.of(ctx).pop(v);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, required this.icon, this.subtitle});

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.veryLightBlue, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.navy, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerBg : AppColors.veryLightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.navy)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Row(children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Chip pilihan bergaya klinik: aktif navy/putih, tidak aktif biru muda/navy.
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.veryLightBlue,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13.5)),
        ),
      ),
    );
  }
}

/// Lebar konten maksimum agar tidak melebar berlebihan di tablet.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
