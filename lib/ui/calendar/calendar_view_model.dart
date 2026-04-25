import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/trip_service.dart';
import '../../domain/models/viaggio.dart';

class CalendarViewModel extends ChangeNotifier {
  final TripService _tripService = TripService();

  List<Viaggio> _viaggi = [];
  DateTime _giornoSelezionato = DateTime.now();
  DateTime _meseVisualizzato = DateTime.now();
  bool _isLoading = true;

  StreamSubscription<List<Viaggio>>? _subscription;

  // --- Getters ---
  bool get isLoading => _isLoading;
  DateTime get giornoSelezionato => _giornoSelezionato;
  DateTime get meseVisualizzato => _meseVisualizzato;

  // Restituisce i viaggi che coprono il giorno selezionato
  List<Viaggio> get viaggiDelGiornoSelezionato {
    return _viaggi.where((v) => _giornoInViaggio(_giornoSelezionato, v)).toList();
  }

  // Costruisce la mappa giorno → lista viaggi (usata da table_calendar)
  Map<DateTime, List<Viaggio>> get eventiPerGiorno {
    final Map<DateTime, List<Viaggio>> mappa = {};

    for (final viaggio in _viaggi) {
      DateTime cursore = _normalizza(viaggio.dataInizio);
      final fine = _normalizza(viaggio.dataFine);

      while (!cursore.isAfter(fine)) {
        mappa[cursore] = [...(mappa[cursore] ?? []), viaggio];
        cursore = cursore.add(const Duration(days: 1));
      }
    }
    return mappa;
  }

  void inizializza(String userId) {
    _subscription = _tripService.streamViaggioAttivi(userId).listen(
      (lista) {
        _viaggi = lista;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void selezionaGiorno(DateTime giorno) {
    _giornoSelezionato = _normalizza(giorno);
    notifyListeners();
  }

  void cambioMese(DateTime mese) {
    _meseVisualizzato = mese;
    notifyListeners();
  }

  // Restituisce il colore assegnato a un viaggio (deterministico)
  Color coloreViaggio(Viaggio viaggio) {
    final colori = [
      const Color(0xFF1E3A8A),
      const Color(0xFF065F46),
      const Color(0xFF7C3AED),
      const Color(0xFF92400E),
      const Color(0xFF9D174D),
      const Color(0xFF0369A1),
    ];
    final index = viaggio.id.hashCode.abs() % colori.length;
    return colori[index];
  }

  bool _giornoInViaggio(DateTime giorno, Viaggio viaggio) {
    final g = _normalizza(giorno);
    final inizio = _normalizza(viaggio.dataInizio);
    final fine = _normalizza(viaggio.dataFine);
    return !g.isBefore(inizio) && !g.isAfter(fine);
  }

  // Normalizza: rimuove ore/minuti/secondi per confronti sicuri
  DateTime _normalizza(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}