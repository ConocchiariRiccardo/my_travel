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
  User? get currentUser => _authService.currentUser;

  AuthViewModel() {
    // Ascolta i cambiamenti di stato dell'autenticazione
    _authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messaggioErrore(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messaggioErrore(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final risultato = await _authService.signInWithGoogle();
      if (risultato == null) return false;
      return true;
    } catch (e) {
      _errorMessage = 'Errore durante l\'accesso con Google. Riprova.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  String _messaggioErrore(String codice) {
    switch (codice) {
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
      default:
        return 'Errore di autenticazione. Riprova.';
    }
  }
}