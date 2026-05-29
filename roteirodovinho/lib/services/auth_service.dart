import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _inicializado = false;

  User? get usuarioAtual {
    return _firebaseAuth.currentUser;
  }

  Future<void> inicializarGoogleSignIn() async {
    if (_inicializado) return;

    await _googleSignIn.initialize();

    _inicializado = true;
  }

  Future<User?> loginComGoogle() async {
    try {
      await inicializarGoogleSignIn();

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return userCredential.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      throw Exception(
        'Erro no Google Sign-In: ${e.code} - ${e.description}',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(
        'Erro no Firebase Auth: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw Exception('Erro ao fazer login com Google: $e');
    }
  }

  Future<void> logout() async {
    await inicializarGoogleSignIn();

    await _googleSignIn.disconnect();
    await _firebaseAuth.signOut();
  }
}
