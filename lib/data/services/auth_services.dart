import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // =========================
  // LOGIN EMAIL + PASSWORD
  // =========================
  Future<User?> signInWithEmail(
      String email,
      String password,
  ) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // =========================
  // REGISTRAZIONE EMAIL
  // =========================
  Future<User?> registerWithEmail(
      String email,
      String password,
  ) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // =========================
  // GOOGLE LOGIN
  // =========================
  /*Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result =
          await _firebaseAuth.signInWithCredential(credential);

      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await GoogleSignIn().signOut();
  }

  // =========================
  // STREAM UTENTE (LOGIN STATE)
  // =========================
  Stream<User?> get userChanges =>
      _firebaseAuth.authStateChanges();
      */
}