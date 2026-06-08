import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);

  bool get _isEmailProvider =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((info) => info.providerId == 'password') ??
      false;

  // ── HELPER DECORATION ─────────────────────────────────────────
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5)),
    );
  }

  // ── CAMBIO EMAIL ──────────────────────────────────────────────
  Future<void> _cambiaEmail() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cambia Email',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Nuova email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: _inputDecoration('Password attuale'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _eseguiCambioEmail(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                },
                child: const Text('Conferma',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eseguiCambioEmail(String nuovaEmail, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(nuovaEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email di verifica inviata. Controlla la tua casella.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore. Controlla la password e riprova.'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    }
  }

  // ── CAMBIO PASSWORD: STEP 1 (verifica identità) ───────────────
  Future<void> _cambiaPassword() async {
    final vecchiaController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Verifica identità',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Inserisci la tua password attuale per continuare.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: vecchiaController,
              obscureText: true,
              decoration: _inputDecoration('Password attuale'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final password = vecchiaController.text.trim();
                  if (password.isEmpty) return;
                  try {
                    final user = FirebaseAuth.instance.currentUser!;
                    final cred = EmailAuthProvider.credential(
                      email: user.email!,
                      password: password,
                    );
                    await user.reauthenticateWithCredential(cred);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (!mounted) return;
                    await _cambiaPasswordStep2(password);
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password non corretta. Riprova.'),
                        backgroundColor: Color(0xFFF44336),
                      ),
                    );
                  }
                },
                child: const Text('Continua',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CAMBIO PASSWORD: STEP 2 (nuova password) ──────────────────
  Future<void> _cambiaPasswordStep2(String vecchiaPassword) async {
    final nuovaController = TextEditingController();
    final confermaController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Nuova Password',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La password deve contenere lettere, numeri e simboli, con una lunghezza compresa tra 8 e 20 caratteri.',
                      style: TextStyle(fontSize: 12, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nuovaController,
              obscureText: true,
              decoration: _inputDecoration('Nuova password'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confermaController,
              obscureText: true,
              decoration: _inputDecoration('Conferma nuova password'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final nuova = nuovaController.text.trim();
                  final conferma = confermaController.text.trim();
                  if (nuova != conferma) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le password non coincidono.'),
                        backgroundColor: Color(0xFFF44336),
                      ),
                    );
                    return;
                  }
                  final regex = RegExp(
                      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,20}$');
                  if (!regex.hasMatch(nuova)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Password non valida. Controlla i requisiti.'),
                        backgroundColor: Color(0xFFF44336),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _eseguiCambioPassword(vecchiaPassword, nuova);
                },
                child: const Text('Salva password',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eseguiCambioPassword(String vecchia, String nuova) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: vecchia,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(nuova);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password aggiornata con successo.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore. Controlla la password attuale e riprova.'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          if (_isEmailProvider) ...[
            _buildSectionLabel('Account'),
            const SizedBox(height: 12),
            _buildTile(
              icon: Icons.email_outlined,
              title: 'Cambia Email',
              onTap: _cambiaEmail,
            ),
            _buildTile(
              icon: Icons.lock_outline,
              title: 'Cambia Password',
              onTap: _cambiaPassword,
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  // ── WIDGET HELPERS ────────────────────────────────────────────
  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A8A),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87, size: 22),
        title: Text(title,
            style: const TextStyle(fontSize: 15, color: Colors.black87)),
        trailing: trailing ??
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF757575)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
