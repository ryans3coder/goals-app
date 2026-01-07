import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? _tryGetFirebaseAuth(),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  static FirebaseAuth? _tryGetFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (error) {
      debugPrint('FirebaseAuth indisponível: $error');
      return null;
    }
  }

  Stream<User?> get authStateChanges =>
      _firebaseAuth?.authStateChanges() ?? Stream<User?>.value(null);

  Future<UserCredential> signInWithGoogle() async {
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null) {
      throw StateError('Firebase indisponível. Tente novamente mais tarde.');
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('Login cancelado pelo usuário.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    final firebaseSignOut =
        _firebaseAuth != null ? _firebaseAuth!.signOut() : Future<void>.value();
    await Future.wait([
      firebaseSignOut,
      _googleSignIn.signOut(),
    ]);
  }
}
