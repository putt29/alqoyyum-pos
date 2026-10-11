import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../repositories/admin_repository.dart';
import '../../widgets/common.dart';

/// Owner: kelola akun kasir (tambah, ubah nama, reset password, aktif/nonaktif).
class CashiersPage extends StatefulWidget {
  const CashiersPage({super.key});

  @override
  State<CashiersPage> createState() => _CashiersPageState();
}

class _CashiersPageState extends State<CashiersPage> {
  int _version = 0;

  void _refresh() => setState(() => _version++);

  Future<void> _addDialog() async {
    final repo = context.read<AdminRepository>();
    final username = TextEditingController();
    final name = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Tambah akun kasir'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: appInput('Nama lengkap'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Nama minimal 2 huruf.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: username,
              autocorrect: false,
              decoration: appInput('Username', hint: 'huruf/angka, min 3 karakter'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Username minimal 3 karakter.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: appInput('Password', hint: 'min 6 karakter'),
              validator: (v) => (v == null || v.length < 6) ? 'Password minimal 6 karakter.' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.of(ctx).pop(true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.createCashier(username: username.text.trim(), fullName: name.text.trim(), password: password.text);
      if (!mounted) return;
      showSnack(context, 'Akun kasir dibuat.');
      _refresh();
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
  }

  Future<void> _editDialog(AppUser user) async {
    final repo = context.read<AdminRepository>();
    final name = TextEditingController(text: user.fullName);
    final password = TextEditingController();
    var active = user.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Ubah ${user.username}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: appInput('Nama lengkap')),
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: true,
              decoration: appInput('Password baru (opsional)', hint: 'kosongkan bila tidak diubah'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Akun aktif'),
              value: active,
              onChanged: (v) => setLocal(() => active = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.updateCashier(
        user.id,
        fullName: name.text.trim(),
        password: password.text.isEmpty ? null : password.text,
        isActive: active,
      );
      if (!mounted) return;
      showSnack(context, 'Akun diperbarui.');
      _refresh();
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Tambah Kasir'),
      ),
      body: ContentWidth(
        maxWidth: 720,
        child: AsyncView<List<AppUser>>(
          loader: () => context.read<AdminRepository>().users(),
          version: _version,
          emptyMessage: 'Belum ada akun.',
          isEmpty: (list) => list.isEmpty,
          builder: (context, users) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _tile(users[i]),
          ),
        ),
      ),
    );
  }

  Widget _tile(AppUser u) {
    return Opacity(
      opacity: u.isActive ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: u.isOwner ? null : () => _editDialog(u),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.veryLightBlue,
                child: Icon(u.isOwner ? Icons.verified_user_outlined : Icons.person_outline, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('@${u.username}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ]),
              ),
              StatusPill(text: u.isOwner ? 'OWNER' : (u.isActive ? 'KASIR' : 'NONAKTIF'), danger: !u.isOwner && !u.isActive),
              if (!u.isOwner) const Icon(Icons.chevron_right, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}
