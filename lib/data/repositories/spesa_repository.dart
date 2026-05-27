import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/spesa.dart';

class SpesaRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> ref(
    String userId,
    String viaggioId,
  ) {
    return db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggioId)
        .collection('spese');
  }

  Stream<List<Spesa>> streamSpese(String userId, String viaggioId) {
    return ref(userId, viaggioId)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Spesa.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<Spesa>> getSpese(String userId, String viaggioId) async {
    final snap =
        await ref(userId, viaggioId).orderBy('data', descending: false).get();

    return snap.docs.map((doc) => Spesa.fromJson(doc.id, doc.data())).toList();
  }

  Future<void> aggiungi(
    String userId,
    String viaggioId,
    Spesa spesa,
  ) async {
    await ref(userId, viaggioId).doc(spesa.id).set(spesa.toJson());
  }

  Future<void> aggiorna(
    String userId,
    String viaggioId,
    Spesa spesa,
  ) async {
    await ref(userId, viaggioId).doc(spesa.id).update(spesa.toJson());
  }

  Future<void> elimina(
    String userId,
    String viaggioId,
    String spesaId,
  ) async {
    await ref(userId, viaggioId).doc(spesaId).delete();
  }

  Future<double> getTotale(String userId, String viaggioId) async {
    final spese = await getSpese(userId, viaggioId);
    return spese.fold<double>(0.0, (somma, s) => somma + s.importo);
  }

  Future<String> caricaScontrino({
    required String userId,
    required String viaggioId,
    required String spesaId,
    required File immagine,
  }) async {
    final storageRef = storage
        .ref()
        .child('users')
        .child(userId)
        .child('viaggi')
        .child(viaggioId)
        .child('scontrini')
        .child('$spesaId.jpg');

    final uploadTask = await storageRef.putFile(
      immagine,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }
}
