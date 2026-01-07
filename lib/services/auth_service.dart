import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_initializer.dart';

abstract class BackupAuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
}

class AuthService implements BackupAuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseInitializationService? firebaseInitializer,
  })  : _firebaseInitializer = firebaseInitializer ?? FirebaseInitializer(),
        _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseInitializationService _firebaseInitializer;
  FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
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
    await _firebaseInitializer.ensureInitialized();
  }

  @override
  Stream<User?> get authStateChanges async* {
    try {
      await _ensureFirebaseReady();
      final firebaseAuth = _getFirebaseAuth();
      if (firebaseAuth == null) {
        yield null;
        return;
      }
      yield* firebaseAuth.authStateChanges();
    } catch (error) {
      debugPrint('Firebase indisponível: $error');
      yield null;
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureFirebaseReady();
    } catch (error) {
      throw StateError('Firebase indisponível. Tente novamente mais tarde.');
    }
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

  @override
  Future<void> signOut() async {
    try {
      await _ensureFirebaseReady();
    } catch (error) {
      debugPrint('Firebase indisponível: $error');
    }
    final firebaseSignOut = _firebaseAuth != null
        ? _firebaseAuth!.signOut()
        : Future<void>.value();
    await Future.wait([
      firebaseSignOut,
      _googleSignIn.signOut(),
    ]);
  }
}
