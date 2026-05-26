import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/attivita.dart';

class ViaggioRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String userId) {
    return _db.collection('users').doc(userId).collection('viaggi');
  }

  CollectionReference<Map<String, dynamic>> _attivitaRef(
    String userId,
    String viaggioId,
  ) {
    return _ref(userId).doc(viaggioId).collection('attivita');
  }

  Stream<List<Viaggio>> streamAttivi(String userId) {
    return _ref(userId)
        .where('isCompletato', isEqualTo: false)
        .orderBy('dataInizio')
        .snapshots()
        .map((snap) {
      final oggi = DateTime.now();
      final mezzanotteOggi = DateTime(oggi.year, oggi.month, oggi.day);
      return snap.docs
          .map((doc) => Viaggio.fromJson(doc.id, doc.data()))
          .where((v) =>
              v.dataFine.isAfter(mezzanotteOggi) || isSameDay(v.dataFine, oggi))
          .toList();
    });
  }

  Stream<List<Viaggio>> streamCompletati(String userId) {
    return _ref(userId)
        .orderBy('dataFine', descending: true)
        .snapshots()
        .map((snap) {
      final oggi = DateTime.now();
      final mezzanotteOggi = DateTime(oggi.year, oggi.month, oggi.day);

      return snap.docs
          .map((doc) => Viaggio.fromJson(doc.id, doc.data()))
          .where((v) => v.dataFine.isBefore(mezzanotteOggi))
          .toList();
    });
  }

  Future<String> crea(String userId, Viaggio viaggio) async {
    final doc = await _ref(userId).add(viaggio.toJson());
    return doc.id;
  }

  Future<void> aggiorna(String userId, Viaggio viaggio) async {
    await _ref(userId).doc(viaggio.id).update(viaggio.toJson());
  }

  Future<void> elimina(String userId, String viaggioId) async {
    final attivita = await _attivitaRef(userId, viaggioId).get();

    final batch = _db.batch();
    for (final doc in attivita.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_ref(userId).doc(viaggioId));
    await batch.commit();
  }

  Future<void> completa(String userId, String viaggioId) async {
    await _ref(userId).doc(viaggioId).update({'isCompletato': true});
  }

  Stream<List<Attivita>> streamAttivita(String userId, String viaggioId) {
    return _attivitaRef(userId, viaggioId).snapshots().map((snap) =>
        snap.docs.map((doc) => Attivita.fromJson(doc.data())).toList());
  }

  Future<void> aggiungi(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    await _attivitaRef(userId, viaggioId)
        .doc(attivita.id)
        .set(attivita.toJson());
  }

  Future<void> toggle(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    await _attivitaRef(userId, viaggioId)
        .doc(attivita.id)
        .update({'isCompletata': !attivita.isCompletata});
  }

  Future<void> eliminaAttivita(
    String userId,
    String viaggioId,
    String attivitaId,
  ) async {
    await _attivitaRef(userId, viaggioId).doc(attivitaId).delete();
  }

  Future<List<Viaggio>> getViaggiFuturi(String userId) async {
    final snapshot = await _ref(userId).get();
    final now = DateTime.now();

    return snapshot.docs
        .map((doc) => Viaggio.fromJson(doc.id, doc.data()))
        .where((viaggio) => viaggio.dataInizio.isAfter(now))
        .toList();
  }
}
