import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';

class NavItem {
  const NavItem({required this.label, required this.icon, this.page, this.action});

  final String label;
  final IconData icon;

  /// Halaman yang ditampilkan di dalam shell.
  final WidgetBuilder? page;

  /// Bila diisi, item ini membuka layar penuh (mis. Transaksi Baru) dan tidak mengganti halaman shell.
  final Future<void> Function(BuildContext context)? action;
}

/// Kerangka navigasi responsif: sidebar (tablet), bottom bar (kasir di HP), drawer (owner di HP).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.items, required this.bottomBarOnPhone});

  final List<NavItem> items;
  final bool bottomBarOnPhone;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;
  int _refresh = 0;

  Future<void> _select(int index) async {
    final item = widget.items[index];
    if (item.action != null) {
      await item.action!(context);
      if (mounted) setState(() => _refresh++);
      return;
    }
    setState(() => _selected = index);
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context,
        title: 'Keluar', message: 'Keluar dari akun ini?', confirmLabel: 'Keluar', destructive: true);
    if (ok && mounted) await context.read<AuthController>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final item = widget.items[_selected];
    final body = KeyedSubtree(key: ValueKey('$_selected-$_refresh'), child: item.page!(context));

    if (wide) {
      return Scaffold(
        body: Row(children: [
          SizedBox(
            width: 250,
            child: _Sidebar(items: widget.items, selected: _selected, onSelect: _select, onLogout: _logout),
          ),
          const VerticalDivider(width: 1, color: AppColors.line),
          Expanded(
            child: Column(children: [
              Container(
                height: 64,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: AppColors.cream,
                child: Text(item.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
              ),
              Expanded(child: body),
            ]),
          ),
        ]),
      );
    }

    final appBar = AppBar(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Row(children: [
        const AppLogo(height: 30),
        const SizedBox(width: 10),
        Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
      ]),
    );

    if (widget.bottomBarOnPhone) {
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected,
          onDestinationSelected: _select,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.veryLightBlue,
          destinations: [for (final it in widget.items) NavigationDestination(icon: Icon(it.icon), label: it.label)],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: _Sidebar(
          items: widget.items,
          selected: _selected,
          onSelect: (i) {
            Navigator.of(context).pop();
            _select(i);
          },
          onLogout: () {
            Navigator.of(context).pop();
            _logout();
          },
        ),
      ),
      body: body,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.selected, required this.onSelect, required this.onLogout});

  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Column(children: [
              const AppLogo(height: 70),
              const SizedBox(height: 8),
              const Text(AppConfig.clinicName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 13.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.account_circle_outlined, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.fullName ?? '-',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(user?.isOwner == true ? 'Owner' : 'Kasir',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    selected: items[i].page != null && i == selected,
                    selectedTileColor: AppColors.veryLightBlue,
                    selectedColor: AppColors.navy,
                    iconColor: AppColors.muted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(items[i].icon),
                    title: Text(items[i].label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => onSelect(i),
                  ),
                ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.line),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Keluar', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            onTap: onLogout,
          ),
        ]),
      ),
    );
  }
}
