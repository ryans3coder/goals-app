import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/backup_snapshot.dart';
import 'firebase_initializer.dart';

abstract class BackupRemoteStore {
  Future<void> uploadSnapshot({
    required String userId,
    required BackupSnapshot snapshot,
  });

  Future<BackupSnapshot?> fetchLatestSnapshot({
    required String userId,
  });
}

class FirebaseBackupRemoteStore implements BackupRemoteStore {
  FirebaseBackupRemoteStore({
    FirebaseInitializationService? firebaseInitializer,
  }) : _firebaseInitializer = firebaseInitializer ?? FirebaseInitializer();

  final FirebaseInitializationService _firebaseInitializer;

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (error) {
      debugPrint('Firestore indisponível: $error');
      return null;
    }
  }

  @override
  Future<void> uploadSnapshot({
    required String userId,
    required BackupSnapshot snapshot,
  }) async {
    await _firebaseInitializer.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase não inicializado.');
    }
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore indisponível.');
    }
    await firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc('latest')
        .set(snapshot.toMap());
  }

  @override
  Future<BackupSnapshot?> fetchLatestSnapshot({
    required String userId,
  }) async {
    await _firebaseInitializer.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase não inicializado.');
    }
    final firestore = _resolveFirestore();
    if (firestore == null) {
      throw StateError('Firestore indisponível.');
    }
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc('latest')
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }
    return BackupSnapshot.fromMap(data);
  }
}
