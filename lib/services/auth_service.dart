import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    Future<void>? firebaseInitialization,
  })  : _firebaseInitialization = firebaseInitialization ?? Future.value(),
        _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final Future<void> _firebaseInitialization;
  FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _getFirebaseAuth()?.currentUser;

  static FirebaseAuth? _tryGetFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (error) {
      debugPrint('FirebaseAuth indisponível: $error');
      return null;
    }
  }

  FirebaseAuth? _getFirebaseAuth() {
    _firebaseAuth ??= _tryGetFirebaseAuth();
    return _firebaseAuth;
  }

  Future<void> _ensureFirebaseReady() async {
    try {
      await _firebaseInitialization;
    } catch (error) {
      debugPrint('Firebase indisponível: $error');
    }
  }

  Stream<User?> get authStateChanges async* {
    await _ensureFirebaseReady();
    final firebaseAuth = _getFirebaseAuth();
    if (firebaseAuth == null) {
      yield null;
      return;
    }
    yield* firebaseAuth.authStateChanges();
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureFirebaseReady();
    final firebaseAuth = _getFirebaseAuth();
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
    await _ensureFirebaseReady();
    final firebaseSignOut =
        _firebaseAuth != null ? _firebaseAuth!.signOut() : Future<void>.value();
    await Future.wait([
      firebaseSignOut,
      _googleSignIn.signOut(),
    ]);
  }
}
