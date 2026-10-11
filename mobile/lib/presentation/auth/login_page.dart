import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../services/local_settings.dart';
import '../../state/auth_controller.dart';
import '../../widgets/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.login(_username.text, _password.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(e);
      });
    }
  }

  Future<void> _serverDialog() async {
    final settings = context.read<LocalSettings>();
    final controller = TextEditingController(text: settings.serverUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Alamat server'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: appInput('URL server', hint: 'http://192.168.1.10:8000'),
          ),
          const SizedBox(height: 8),
          const Text('Isi alamat server klinik (komputer/VPS yang menjalankan backend).',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Simpan')),
        ],
      ),
    );
    if (saved == true) {
      await settings.setServerUrl(controller.text);
      if (mounted) showSnack(context, 'Alamat server disimpan: ${settings.serverUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AuthController>().notice;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Center(child: AppLogo(height: 150, full: true)),
                    const SizedBox(height: 14),
                    const Text(AppConfig.clinicName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    const Text('Aplikasi Kasir', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 24),
                    if (notice != null || _error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(_error ?? notice!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: appInput('Username', prefix: const Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: appInput(
                        'Password',
                        prefix: const Icon(Icons.lock_outline),
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi.' : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 18),
                    const Text(AppConfig.address,
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    const Text('Telp ${AppConfig.phone} · WA ${AppConfig.whatsapp}',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              tooltip: 'Alamat server',
              icon: const Icon(Icons.settings_ethernet, color: AppColors.navy),
              onPressed: _serverDialog,
            ),
          ),
        ]),
      ),
    );
  }
}
