import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.currentUser != null;

  AuthViewModel() {
    _authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.register(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) {
        // L'utente ha annullato l'operazione, non mostriamo errori ma fermiamo il caricamento
        _setLoading(false);
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError("Errore durante l'accesso con Google. Riprova.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  void clearError() {
    _setError(null);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nessun account trovato con questa email.';
      case 'wrong-password':
        return 'Password errata. Riprova.';
      case 'email-already-in-use':
        return 'Email già in uso. Prova ad accedere.';
      case 'weak-password':
        return 'La password deve avere almeno 6 caratteri.';
      case 'invalid-email':
        return 'Formato email non valido.';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova tra qualche minuto.';
      default:
        return 'Errore di autenticazione. Riprova.';
    }
  }
}
