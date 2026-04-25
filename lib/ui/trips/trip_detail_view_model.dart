import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/trip_service.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/attivita.dart';

class TripDetailViewModel extends ChangeNotifier {
  final TripService _tripService = TripService();

  Viaggio? _viaggio;
  List<Attivita> _attivita = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<Viaggio>>? _viaggioSub;
  StreamSubscription<List<Attivita>>? _attivitaSub;

  // --- Getters ---
  Viaggio? get viaggio => _viaggio;
  List<Attivita> get attivita => _attivita;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get percentualeCompletamento {
    if (_attivita.isEmpty) return 0;
    final completate = _attivita.where((a) => a.isCompletata).length;
    return completate / _attivita.length;
  }

  void inizializza(String userId, String viaggioId) {
    // Stream del viaggio (per aggiornamenti real-time al titolo, date, ecc.)
    _viaggioSub = _tripService.streamViaggioAttivi(userId).listen((lista) {
      try {
        _viaggio = lista.firstWhere((v) => v.id == viaggioId);
      } catch (_) {
        // Il viaggio potrebbe essere già nello storico
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _errorMessage = 'Errore nel caricamento del viaggio.';
      _isLoading = false;
      notifyListeners();
    });

    // Stream delle attività
    _attivitaSub =
        _tripService.streamAttivita(userId, viaggioId).listen((lista) {
      _attivita = lista;
      notifyListeners();
    }, onError: (_) {
      _errorMessage = 'Errore nel caricamento delle attività.';
      notifyListeners();
    });
  }

  Future<void> toggleAttivita(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    try {
      await _tripService.toggleAttivita(userId, viaggioId, attivita);
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare l\'attività.';
      notifyListeners();
    }
  }

  Future<void> eliminaAttivita(
    String userId,
    String viaggioId,
    String attivitaId,
  ) async {
    try {
      await _tripService.eliminaAttivita(userId, viaggioId, attivitaId);
    } catch (_) {
      _errorMessage = 'Impossibile eliminare l\'attività.';
      notifyListeners();
    }
  }

  Future<bool> aggiungiAttivita(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    try {
      await _tripService.aggiungiAttivita(userId, viaggioId, attivita);
      return true;
    } catch (_) {
      _errorMessage = 'Impossibile aggiungere l\'attività.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completaViaggio(String userId, String viaggioId) async {
    try {
      await _tripService.completaViaggio(userId, viaggioId);
      return true;
    } catch (_) {
      _errorMessage = 'Impossibile completare il viaggio.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _viaggioSub?.cancel();
    _attivitaSub?.cancel();
    super.dispose();
  }
}
