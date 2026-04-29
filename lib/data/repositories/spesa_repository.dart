import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/spesa.dart';

class SpesaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(
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

  Stream<List<Spesa>> streamSpese(String userId, String viaggioId) {
    return _ref(userId, viaggioId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Spesa.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<List<Spesa>> getSpese(String userId, String viaggioId) async {
    final snap = await _ref(userId, viaggioId)
        .orderBy('data', descending: false)
        .get();
    return snap.docs
        .map((doc) => Spesa.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<void> aggiungi(
    String userId,
    String viaggioId,
    Spesa spesa,
  ) async {
    await _ref(userId, viaggioId).doc(spesa.id).set(spesa.toJson());
  }

  Future<void> aggiorna(
    String userId,
    String viaggioId,
    Spesa spesa,
  ) async {
    await _ref(userId, viaggioId).doc(spesa.id).update(spesa.toJson());
  }

  Future<void> elimina(
    String userId,
    String viaggioId,
    String spesaId,
  ) async {
    await _ref(userId, viaggioId).doc(spesaId).delete();
  }

  Future<double> getTotale(String userId, String viaggioId) async {
    final spese = await getSpese(userId, viaggioId);
    return spese.fold<double>(0.0, (somma, s) => somma + s.importo);
  }
}