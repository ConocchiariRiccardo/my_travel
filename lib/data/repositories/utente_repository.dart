import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/utente.dart';

class UtenteRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('users');

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
    await _auth.currentUser?.updateDisplayName(nuovoNome);
  }
}