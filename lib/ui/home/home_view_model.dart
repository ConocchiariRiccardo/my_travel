import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/trip_service.dart';
import '../../domain/models/viaggio.dart';

class HomeViewModel extends ChangeNotifier {
  final TripService _tripService = TripService();

  List<Viaggio> _tutti = [];
  List<Viaggio> _viaggiFiltrati = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filtroCorrente = 'tutti'; // 'tutti' | 'in_corso' | 'in_arrivo'
  String _testoDiRicerca = '';

  StreamSubscription<List<Viaggio>>? _subscription;

  // --- Getters ---
  List<Viaggio> get viaggi => _viaggiFiltrati;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filtroCorrente => _filtroCorrente;

  // Inizializza lo stream per un utente specifico
  void inizializza(String userId) {
    _isLoading = true;
    notifyListeners();

    _subscription = _tripService.streamViaggioAttivi(userId).listen(
      (lista) {
        _tutti = lista;
        _applicaFiltri();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Errore nel caricamento dei viaggi.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Applica filtro per stato
  void impostaFiltro(String filtro) {
    _filtroCorrente = filtro;
    _applicaFiltri();
    notifyListeners();
  }

  // Aggiorna il testo di ricerca
  void cercaViaggio(String testo) {
    _testoDiRicerca = testo.toLowerCase();
    _applicaFiltri();
    notifyListeners();
  }

  void _applicaFiltri() {
    List<Viaggio> risultato = List.from(_tutti);

    // Filtro per stato
    switch (_filtroCorrente) {
      case 'in_corso':
        risultato = risultato.where((v) => v.isInCorso).toList();
        break;
      case 'in_arrivo':
        risultato = risultato.where((v) => v.giorniAllaPartenza > 0).toList();
        break;
      default: // 'tutti'
        break;
    }

    // Filtro per testo di ricerca
    if (_testoDiRicerca.isNotEmpty) {
      risultato = risultato
          .where((v) =>
              v.nome.toLowerCase().contains(_testoDiRicerca) ||
              v.destinazione.toLowerCase().contains(_testoDiRicerca))
          .toList();
    }

    _viaggiFiltrati = risultato;
  }

  Future<void> eliminaViaggio(String userId, String viaggioId) async {
    try {
      await _tripService.eliminaViaggio(userId, viaggioId);
    } catch (e) {
      _errorMessage = 'Impossibile eliminare il viaggio.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
