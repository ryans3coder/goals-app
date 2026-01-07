import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/routine.dart';

class DataProvider {
  DataProvider({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? _tryGetFirestore(),
        _firebaseAuth = firebaseAuth ?? _tryGetFirebaseAuth();

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _firebaseAuth;

  static bool _hasFirebaseApp() => Firebase.apps.isNotEmpty;

  static FirebaseFirestore? _tryGetFirestore() {
    if (!_hasFirebaseApp()) {
      return null;
    }
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth? _tryGetFirebaseAuth() {
    if (!_hasFirebaseApp()) {
      return null;
    }
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String get _userId {
    final user = _firebaseAuth?.currentUser;
    if (user == null) {
      return 'guest';
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _habitsCollection(
    FirebaseFirestore firestore,
  ) =>
      firestore.collection('habits');

  CollectionReference<Map<String, dynamic>> _routinesCollection(
    FirebaseFirestore firestore,
  ) =>
      firestore.collection('routines');

  CollectionReference<Map<String, dynamic>> _goalsCollection(
    FirebaseFirestore firestore,
  ) =>
      firestore.collection('goals');

  CollectionReference<Map<String, dynamic>> _routineHistoryCollection(
    FirebaseFirestore firestore,
  ) =>
      firestore.collection('routine_history');

  FirebaseFirestore? get _firestoreSafe => _firestore ?? _tryGetFirestore();

  Future<void> addHabit(Habit habit) async {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return;
    }
    try {
      final userId = _userId;
      final collection = _habitsCollection(firestore);
      final docRef = habit.id.isNotEmpty
          ? collection.doc(habit.id)
          : collection.doc();
      final data = habit.toMap()
        ..['id'] = docRef.id
        ..['userId'] = userId;
      await docRef.set(data);
    } catch (_) {
      return;
    }
  }

  Stream<List<Habit>> watchHabits() {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      final userId = _userId;
      return _habitsCollection(firestore)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Habit.fromMap(doc.data(), id: doc.id))
              .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<void> updateHabitCompletion({
    required Habit habit,
    required bool isCompletedToday,
  }) async {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return;
    }
    try {
      if (habit.id.isEmpty) {
        throw StateError('Habit sem ID não pode ser atualizado.');
      }

      var updatedStreak = habit.currentStreak;
      if (isCompletedToday && !habit.isCompletedToday) {
        updatedStreak += 1;
      } else if (!isCompletedToday && habit.isCompletedToday) {
        updatedStreak = updatedStreak > 0 ? updatedStreak - 1 : 0;
      }

      await _habitsCollection(firestore).doc(habit.id).update({
        'isCompletedToday': isCompletedToday,
        'currentStreak': updatedStreak,
      });
    } catch (_) {
      return;
    }
  }

  Future<void> addRoutine(Routine routine) async {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return;
    }
    try {
      final userId = _userId;
      final collection = _routinesCollection(firestore);
      final docRef = routine.id.isNotEmpty
          ? collection.doc(routine.id)
          : collection.doc();
      final data = routine.toMap()
        ..['id'] = docRef.id
        ..['userId'] = userId;
      await docRef.set(data);
    } catch (_) {
      return;
    }
  }

  Stream<List<Routine>> watchRoutines() {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      final userId = _userId;
      return _routinesCollection(firestore)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Routine.fromMap(doc.data(), id: doc.id))
              .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<void> addRoutineHistory({
    required Routine routine,
    DateTime? completedAt,
  }) async {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return;
    }
    try {
      final userId = _userId;
      final docRef = _routineHistoryCollection(firestore).doc();
      final timestamp = completedAt ?? DateTime.now();
      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'routineId': routine.id,
        'routineTitle': routine.title,
        'completedAt': Timestamp.fromDate(timestamp),
        'steps': routine.steps,
      });
    } catch (_) {
      return;
    }
  }

  Future<void> addGoal(Goal goal) async {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return;
    }
    try {
      final userId = _userId;
      final collection = _goalsCollection(firestore);
      final docRef = goal.id.isNotEmpty
          ? collection.doc(goal.id)
          : collection.doc();
      final data = goal.toMap()
        ..['id'] = docRef.id
        ..['userId'] = userId;
      await docRef.set(data);
    } catch (_) {
      return;
    }
  }

  Stream<List<Goal>> watchGoals() {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return Stream.value([]);
    }
    try {
      final userId = _userId;
      return _goalsCollection(firestore)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Goal.fromMap(doc.data(), id: doc.id))
              .toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<void> updateGoalMilestones({
    required Goal goal,
  }) async {
    final firestore = _firestoreSafe;
    if (firestore == null) {
      return;
    }
    try {
      if (goal.id.isEmpty) {
        throw StateError('Goal sem ID não pode ser atualizado.');
      }

      await _goalsCollection(firestore).doc(goal.id).update({
        'milestones':
            goal.milestones.map((milestone) => milestone.toMap()).toList(),
      });
    } catch (_) {
      return;
    }
  }
}
