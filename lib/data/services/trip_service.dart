import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/attivita.dart';
import 'notification_service.dart';

class TripService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Riferimento alla collection viaggi di un utente specifico
  CollectionReference<Map<String, dynamic>> _viaggiRef(String userId) {
    return _db.collection('users').doc(userId).collection('viaggi');
  }

  // Riferimento alla sub-collection attività di un viaggio
  CollectionReference<Map<String, dynamic>> _attivitaRef(
    String userId,
    String viaggioId,
  ) {
    return _viaggiRef(userId).doc(viaggioId).collection('attivita');
  }

  // --- CRUD VIAGGI ---

  // Stream real-time dei viaggi attivi (non completati)
  Stream<List<Viaggio>> streamViaggioAttivi(String userId) {
    return _viaggiRef(userId)
        .where('isCompletato', isEqualTo: false)
        .orderBy('dataInizio')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Viaggio.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Stream real-time dello storico (viaggi completati)
  Stream<List<Viaggio>> streamViaggiCompletati(String userId) {
    return _viaggiRef(userId)
        .where('isCompletato', isEqualTo: true)
        .orderBy('dataFine', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Viaggio.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Crea un nuovo viaggio
  Future<String> creaViaggio(String userId, Viaggio viaggio) async {
    final docRef = await _viaggiRef(userId).add(viaggio.toJson());

    // Schedula notifica di partenza automaticamente
    final notifService = NotificationService();
    await notifService.schedulaNotificaPartenza(
      id: notifService.idDaViaggioId(docRef.id),
      nomeViaggio: viaggio.nome,
      destinazione: viaggio.destinazione,
      dataPartenza: viaggio.dataInizio,
    );

    return docRef.id;
  }

  // Aggiorna un viaggio esistente
  Future<void> aggiornaViaggio(String userId, Viaggio viaggio) async {
    await _viaggiRef(userId).doc(viaggio.id).update(viaggio.toJson());
  }

  // Elimina un viaggio e tutte le sue attività
  Future<void> eliminaViaggio(String userId, String viaggioId) async {
    final notifService = NotificationService();
    await notifService.cancellaNotifica(
      notifService.idDaViaggioId(viaggioId),
    );

    final attivitaSnapshot = await _attivitaRef(userId, viaggioId).get();
    for (final doc in attivitaSnapshot.docs) {
      await doc.reference.delete();
    }
    await _viaggiRef(userId).doc(viaggioId).delete();
  }

  // Segna un viaggio come completato
  Future<void> completaViaggio(String userId, String viaggioId) async {
    await _viaggiRef(userId).doc(viaggioId).update({'isCompletato': true});
  }

  // --- CRUD ATTIVITÀ ---

  Stream<List<Attivita>> streamAttivita(String userId, String viaggioId) {
    return _attivitaRef(userId, viaggioId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Attivita.fromJson(doc.data())).toList());
  }

  Future<void> aggiungiAttivita(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    await _attivitaRef(userId, viaggioId)
        .doc(attivita.id)
        .set(attivita.toJson());
  }

  Future<void> toggleAttivita(
    String userId,
    String viaggioId,
    Attivita attivita,
  ) async {
    await _attivitaRef(userId, viaggioId).doc(attivita.id).update(
      {'isCompletata': !attivita.isCompletata},
    );
  }

  Future<void> eliminaAttivita(
    String userId,
    String viaggioId,
    String attivitaId,
  ) async {
    await _attivitaRef(userId, viaggioId).doc(attivitaId).delete();
  }
}
