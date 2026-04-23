import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Avvia il flusso di login di Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // Se l'utente chiude la finestra di Google senza accedere, ritorniamo null
    if (googleUser == null) return null;

    // Otteniamo le credenziali di autenticazione da Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Creiamo una nuova credenziale Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Eseguiamo l'accesso su Firebase con la credenziale Google
    return await _auth.signInWithCredential(credential);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
