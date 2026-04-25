import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/spesa.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _speseRef(
    String userId,
    String viaggioId,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggioId)
        .collection('spese');
  }

  // Stream real-time delle spese di un viaggio
  Stream<List<Spesa>> streamSpese(String userId, String viaggioId) {
    return _speseRef(userId, viaggioId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Spesa.fromJson(d.id, d.data())).toList());
  }

  // Recupero singolo (per generazione PDF)
  Future<List<Spesa>> getSpese(String userId, String viaggioId) async {
    final snap = await _speseRef(userId, viaggioId)
        .orderBy('data', descending: false)
        .get();
    return snap.docs.map((d) => Spesa.fromJson(d.id, d.data())).toList();
  }

  Future<void> aggiungiSpesa(
    String userId,
    String viaggioId,
    Spesa spesa,
  ) async {
    await _speseRef(userId, viaggioId).doc(spesa.id).set(spesa.toJson());
  }

  Future<void> aggiornaSpesa(
    String userId,
    String viaggioId,
    Spesa spesa,
  ) async {
    await _speseRef(userId, viaggioId).doc(spesa.id).update(spesa.toJson());
  }

  Future<void> eliminaSpesa(
    String userId,
    String viaggioId,
    String spesaId,
  ) async {
    await _speseRef(userId, viaggioId).doc(spesaId).delete();
  }

  // Totale spese di un viaggio
  Future<double> getTotaleSpese(String userId, String viaggioId) async {
    final spese = await getSpese(userId, viaggioId);
    return spese.fold<double>(0.0, (somma, s) => somma + s.importo);
  }
}
