import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisibile = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final authViewModel = context.read<AuthViewModel>();
    final successo = await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (successo) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authViewModel.errorMessage ?? 'Errore di accesso.',
                key: const Key('login-error-snackbar'),
              ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _loginGoogle() async {
    FocusScope.of(context).unfocus();

    final authViewModel = context.read<AuthViewModel>();
    final successo = await authViewModel.loginWithGoogle();

    if (!mounted) return;

    if (successo) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (authViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authViewModel.errorMessage!,
                key: const Key('login-error-snackbar'),
              ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = (screenWidth * 0.42).clamp(120.0, 180.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bentornato',
                  key: const Key('login-title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accedi per gestire viaggi, attività e trasferte in modo semplice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                _buildSectionLabel('Credenziali'),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('email-field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 15,
                    color: textPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Email',
                    hint: 'nome@azienda.it',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('password-field'),
                  controller: _passwordController,
                  obscureText: !_passwordVisibile,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => isLoading ? null : _login(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: textPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    label: 'Password',
                    hint: 'Inserisci la password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      key: const Key('password-visibility-btn'),
                      splashRadius: 20,
                      icon: Icon(
                        _passwordVisibile
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisibile = !_passwordVisibile;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('login-btn'),
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryColor.withOpacity(0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                      ? const SizedBox(
                        key: Key('login-loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Accedi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'oppure',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    key: const Key('google-btn'),
                    onPressed: isLoading ? null : _loginGoogle,
                    style: OutlinedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: textPrimary,
                      side: const BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.account_circle_outlined,
                          color: primaryColor,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Accedi con Google',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Non hai un account? ',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      key: const Key('register-link'),
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Registrati',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
    );
  }
}
