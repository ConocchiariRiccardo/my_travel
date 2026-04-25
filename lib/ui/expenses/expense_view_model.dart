import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/expense_service.dart';
import '../../domain/models/spesa.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Spesa> _spese = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Spesa>>? _subscription;

  // --- Getters ---
  List<Spesa> get spese => _spese;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totale => _spese.fold(0.0, (somma, s) => somma + s.importo);

  String get totaleFormattato =>
      '€ ${totale.toStringAsFixed(2).replaceAll('.', ',')}';

  // Raggruppa le spese per categoria per il riepilogo
  Map<String, double> get totalePerCategoria {
    final Map<String, double> mappa = {};
    for (final spesa in _spese) {
      mappa[spesa.categoria] = (mappa[spesa.categoria] ?? 0) + spesa.importo;
    }
    return mappa;
  }

  void inizializza(String userId, String viaggioId) {
    _subscription = _expenseService.streamSpese(userId, viaggioId).listen(
      (lista) {
        _spese = lista;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Errore nel caricamento delle spese.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> eliminaSpesa(
    String userId,
    String viaggioId,
    String spesaId,
  ) async {
    try {
      await _expenseService.eliminaSpesa(userId, viaggioId, spesaId);
    } catch (_) {
      _errorMessage = 'Impossibile eliminare la spesa.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
