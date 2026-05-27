import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/viaggio_repository.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/attivita.dart';

class TripDetailViewModel extends ChangeNotifier {
  final ViaggioRepository _viaggioRepo = ViaggioRepository();

  Viaggio? _viaggio;
  List<Attivita> _attivita = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<List<Viaggio>>? _viaggioAttiviSub;
  StreamSubscription<List<Viaggio>>? _viaggioStoricoSub;
  StreamSubscription<List<Attivita>>? _attivitaSub;

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
    _viaggioAttiviSub = _viaggioRepo.streamAttivi(userId).listen(
      (lista) {
        Viaggio? trovato;
        for (final v in lista) {
          if (v.id == viaggioId) {
            trovato = v;
            break;
          }
        }

        if (trovato != null) {
          _viaggio = trovato;
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Errore nel caricamento del viaggio.';
        _isLoading = false;
        notifyListeners();
      },
    );

    _viaggioStoricoSub = _viaggioRepo.streamCompletati(userId).listen(
      (lista) {
        Viaggio? trovato;
        for (final v in lista) {
          if (v.id == viaggioId) {
            trovato = v;
            break;
          }
        }

        if (trovato != null) {
          _viaggio = trovato;
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (_) {
        _errorMessage = 'Errore nel caricamento del viaggio nello storico.';
        _isLoading = false;
        notifyListeners();
      },
    );

    _attivitaSub = _viaggioRepo.streamAttivita(userId, viaggioId).listen(
      (lista) {
        _attivita = lista;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Errore nel caricamento delle attività.';
        notifyListeners();
      },
    );
  }

  Future<void> toggle(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    try {
      await _viaggioRepo.toggle(userId, viaggioId, attivita);
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare l\'attività.';
      notifyListeners();
    }
  }

  Future<void> elimina(
    String userId,
    String viaggioId,
    String attivitaId,
  ) async {
    try {
      await _viaggioRepo.eliminaAttivita(userId, viaggioId, attivitaId);
    } catch (_) {
      _errorMessage = 'Impossibile eliminare l\'attività.';
      notifyListeners();
    }
  }

  Future<bool> aggiungi(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    try {
      await _viaggioRepo.aggiungi(userId, viaggioId, attivita);
      return true;
    } catch (_) {
      _errorMessage = 'Impossibile aggiungere l\'attività.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completa(String userId, String viaggioId) async {
    try {
      await _viaggioRepo.completa(userId, viaggioId);
      return true;
    } catch (_) {
      _errorMessage = 'Impossibile completare il viaggio.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _viaggioAttiviSub?.cancel();
    _viaggioStoricoSub?.cancel();
    _attivitaSub?.cancel();
    super.dispose();
  }
}
