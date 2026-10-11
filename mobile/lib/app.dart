import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/splash_page.dart';
import 'presentation/shell/cashier_shell.dart';
import 'presentation/shell/owner_shell.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';

class AlqoyyumApp extends StatelessWidget {
  const AlqoyyumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AL-QOYYUM Kasir',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Batasi skala font sistem agar kartu/tombol tidak overflow.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthGate(),
    );
  }
}

/// Memilih halaman berdasarkan status login & role (Owner / Kasir).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (_last != auth.status) {
      final wasSignedIn = _last == AuthStatus.signedIn;
      _last = auth.status;
      if (wasSignedIn && auth.status == AuthStatus.signedOut) {
        // Bersihkan cache & draft transaksi setelah logout.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<CatalogController>().reset();
          context.read<CartController>().clear();
        });
      }
    }
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashPage();
      case AuthStatus.signedOut:
        return const LoginPage();
      case AuthStatus.signedIn:
        return auth.isOwner ? const OwnerShell() : const CashierShell();
    }
  }
}
