import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../repositories/admin_repository.dart';
import '../../services/local_settings.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/tx_tile.dart';

/// Pengaturan (Owner) / Profil (Kasir): akun, ganti password, alamat server, nomor kwitansi, keluar.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _version = 0;

  Future<void> _changePassword() async {
    final auth = context.read<AuthController>();
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Ganti password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: oldPw,
              obscureText: true,
              decoration: appInput('Password lama'),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: newPw,
              obscureText: true,
              decoration: appInput('Password baru', hint: 'min 6 karakter'),
              validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter.' : null,
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
      await auth.changePassword(oldPw.text, newPw.text);
      if (mounted) showSnack(context, 'Password berhasil diganti.');
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
  }

  Future<void> _serverDialog() async {
    final settings = context.read<LocalSettings>();
    final controller = TextEditingController(text: settings.serverUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Alamat server'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: appInput('URL server', hint: 'http://192.168.1.10:8000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    await settings.setServerUrl(controller.text);
    if (mounted) {
      showSnack(context, 'Alamat server disimpan.');
      setState(() => _version++);
    }
  }

  Future<void> _numberingDialog(int current) async {
    final repo = context.read<AdminRepository>();
    final controller = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Nomor kwitansi berikutnya'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: appInput('Nomor urut berikutnya'),
          ),
          const SizedBox(height: 8),
          const Text('Format nomor mengikuti Excel: NO : {urut}/{BBTT}, mis. 368/1026.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final v = parseDigits(controller.text);
              if (v < 1) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    try {
      await repo.setNextSequence(value);
      if (!mounted) return;
      showSnack(context, 'Nomor berikutnya: $value');
      setState(() => _version++);
    } catch (e) {
      if (mounted) showSnack(context, errorMessage(e), error: true);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthController>();
    final ok = await confirmDialog(context,
        title: 'Keluar', message: 'Keluar dari akun ini?', confirmLabel: 'Keluar', destructive: true);
    if (ok) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final settings = context.read<LocalSettings>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      ContentWidth(
        maxWidth: 640,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          whiteCard(
            child: Row(children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.veryLightBlue,
                child: Icon(Icons.person_outline, color: AppColors.navy, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? '-', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('@${user?.username ?? '-'}', style: const TextStyle(color: AppColors.muted)),
                ]),
              ),
              StatusPill(text: auth.isOwner ? 'OWNER' : 'KASIR'),
            ]),
          ),
          const SectionTitle('Akun'),
          _action(Icons.vpn_key_outlined, 'Ganti password', 'Ubah password akun Anda', _changePassword),
          const SectionTitle('Koneksi'),
          _action(Icons.dns_outlined, 'Alamat server', settings.serverUrl, _serverDialog),
          if (auth.isOwner) ...[
            const SectionTitle('Nomor kwitansi'),
            AsyncView<int>(
              loader: () => context.read<AdminRepository>().nextSequence(),
              version: _version,
              builder: (context, seq) => _action(
                  Icons.tag, 'Nomor berikutnya: $seq', 'Format NO : $seq/{BBTT} (mengikuti Excel)', () => _numberingDialog(seq)),
            ),
          ],
          const SectionTitle('Tentang'),
          whiteCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text(AppConfig.clinicName, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
              SizedBox(height: 4),
              Text(AppConfig.address, style: TextStyle(color: AppColors.muted)),
              Text('Telp ${AppConfig.phone} · WA ${AppConfig.whatsapp}', style: TextStyle(color: AppColors.muted)),
              Text('No. SIPD ${AppConfig.sipd}', style: TextStyle(color: AppColors.muted)),
              SizedBox(height: 4),
              Text('Dokter: ${AppConfig.doctorName}', style: TextStyle(color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ]),
      ),
    ]);
  }

  Widget _action(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Icon(icon, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}
