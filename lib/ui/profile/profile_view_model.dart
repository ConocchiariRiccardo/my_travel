import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/utente.dart';
import '../../data/repositories/utente_repository.dart';
import 'dart:io';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UtenteRepository _utenteRepo = UtenteRepository();

  Utente? _utente;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // --- Getters ---
  Utente? get utente => _utente;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Email dell'utente loggato (sempre disponibile da Auth)
  String get email => _auth.currentUser?.email ?? '';

  ProfileViewModel() {
    _caricaProfilo();
  }

  Future<void> _caricaProfilo() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _utenteRepo.getUtente(uid);

      if (doc != null) {
        _utente = doc;
      } else {
        _utente = Utente(
          id: uid,
          email: _auth.currentUser?.email ?? '',
          nomeCompleto: _auth.currentUser?.displayName,
          fotoProfiloUrl: _auth.currentUser?.photoURL,
        );
        await _utenteRepo.crea(_utente!);
      }
    } catch (_) {
      _errorMessage = 'Errore nel caricamento del profilo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> aggiornaNome(String nuovoNome) async {
    if (nuovoNome.trim().isEmpty) return;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser!.uid;

      await _utenteRepo.aggiornaNome(uid, nuovoNome.trim());

      // Aggiorna anche il displayName su Firebase Auth
      await _auth.currentUser!.updateDisplayName(nuovoNome.trim());

      _utente = Utente(
        id: _utente!.id,
        email: _utente!.email,
        nomeCompleto: nuovoNome.trim(),
        fotoProfiloUrl: _utente!.fotoProfiloUrl,
      );

      _successMessage = 'Nome aggiornato con successo!';
    } catch (_) {
      _errorMessage = 'Errore durante l\'aggiornamento. Riprova.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> aggiornaFotoProfilo(File immagine) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser!.uid;

      final fotoUrl = await _utenteRepo.caricaFotoProfilo(uid, immagine);
      await _utenteRepo.aggiornaFotoProfilo(uid, fotoUrl);

      _utente = Utente(
        id: _utente!.id,
        email: _utente!.email,
        nomeCompleto: _utente!.nomeCompleto,
        fotoProfiloUrl: fotoUrl,
      );

      _successMessage = 'Foto profilo aggiornata!';
    } catch (_) {
      _errorMessage = 'Errore durante il caricamento della foto. Riprova.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
