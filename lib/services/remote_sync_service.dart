import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/routine.dart';
import 'auth_service.dart';
import 'local_data_store.dart';

abstract class RemoteSyncService {
  Future<void> enqueueSync(LocalSnapshot snapshot);
}

class NoopRemoteSyncService implements RemoteSyncService {
  @override
  Future<void> enqueueSync(LocalSnapshot snapshot) async {}
}

class FirebaseRemoteSyncService implements RemoteSyncService {
  FirebaseRemoteSyncService({
    AuthService? authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? AuthService(),
        _firestore = firestore ?? _tryGetFirestore();

  final AuthService _authService;
  final FirebaseFirestore? _firestore;
  Future<void> _syncQueue = Future.value();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (error) {
      debugPrint('Firestore indisponível: $error');
      return null;
    }
  }

  @override
  Future<void> enqueueSync(LocalSnapshot snapshot) {
    _syncQueue = _syncQueue.then((_) => _sync(snapshot));
    return _syncQueue;
  }

  Future<void> _sync(LocalSnapshot snapshot) async {
    final firestore = _firestore;
    final user = _authService.currentUser;
    if (firestore == null || user == null) {
      return;
    }

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest')
          .set(
            {
              'updatedAt': DateTime.now().toIso8601String(),
              'habits': _encodeHabits(snapshot.habits),
              'routines': _encodeRoutines(snapshot.routines),
              'goals': _encodeGoals(snapshot.goals),
            },
            SetOptions(merge: true),
          );
    } catch (error) {
      debugPrint('Falha ao sincronizar backup remoto: $error');
    }
  }

  List<Map<String, dynamic>> _encodeHabits(List<Habit> habits) {
    return habits.map((habit) => habit.toMap()).toList();
  }

  List<Map<String, dynamic>> _encodeRoutines(List<Routine> routines) {
    return routines.map((routine) => routine.toMap()).toList();
  }

  List<Map<String, dynamic>> _encodeGoals(List<Goal> goals) {
    return goals.map((goal) => goal.toMap()).toList();
  }
}
