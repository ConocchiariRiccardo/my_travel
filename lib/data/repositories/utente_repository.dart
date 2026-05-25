import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/utente.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UtenteRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _ref => _db.collection('users');

  Future<Utente?> getUtente(String userId) async {
    final doc = await _ref.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Utente.fromJson(userId, doc.data()!);
  }

  Future<void> crea(Utente utente) async {
    await _ref.doc(utente.id).set(utente.toJson());
  }

  Future<void> aggiornaNome(String userId, String nuovoNome) async {
    await _ref.doc(userId).update({'nomeCompleto': nuovoNome});
  }

  /// Carica la foto profilo su Firebase Storage e restituisce il download URL.
  Future<String> caricaFotoProfilo(String userId, File immagine) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$userId.jpg');

    final uploadTask = ref.putFile(
      immagine,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> aggiornaFotoProfilo(String userId, String fotoUrl) async {
    await _ref.doc(userId).update({'fotoProfiloUrl': fotoUrl});
    await _auth.currentUser?.updatePhotoURL(fotoUrl);
  }
}
