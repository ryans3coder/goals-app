import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/routine.dart';

class DataProvider {
  DataProvider({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _habitsCollection =>
      _firestore.collection('habits');

  CollectionReference<Map<String, dynamic>> get _routinesCollection =>
      _firestore.collection('routines');

  CollectionReference<Map<String, dynamic>> get _goalsCollection =>
      _firestore.collection('goals');

  CollectionReference<Map<String, dynamic>> get _routineHistoryCollection =>
      _firestore.collection('routine_history');

  Future<void> addHabit(Habit habit) async {
    final userId = _userId;
    final docRef = habit.id.isNotEmpty
        ? _habitsCollection.doc(habit.id)
        : _habitsCollection.doc();
    final data = habit.toMap()
      ..['id'] = docRef.id
      ..['userId'] = userId;
    await docRef.set(data);
  }

  Stream<List<Habit>> watchHabits() {
    final userId = _userId;
    return _habitsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Habit.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> updateHabitCompletion({
    required Habit habit,
    required bool isCompletedToday,
  }) async {
    if (habit.id.isEmpty) {
      throw StateError('Habit sem ID não pode ser atualizado.');
    }

    var updatedStreak = habit.currentStreak;
    if (isCompletedToday && !habit.isCompletedToday) {
      updatedStreak += 1;
    } else if (!isCompletedToday && habit.isCompletedToday) {
      updatedStreak = updatedStreak > 0 ? updatedStreak - 1 : 0;
    }

    await _habitsCollection.doc(habit.id).update({
      'isCompletedToday': isCompletedToday,
      'currentStreak': updatedStreak,
    });
  }

  Future<void> addRoutine(Routine routine) async {
    final userId = _userId;
    final docRef = routine.id.isNotEmpty
        ? _routinesCollection.doc(routine.id)
        : _routinesCollection.doc();
    final data = routine.toMap()
      ..['id'] = docRef.id
      ..['userId'] = userId;
    await docRef.set(data);
  }

  Stream<List<Routine>> watchRoutines() {
    final userId = _userId;
    return _routinesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Routine.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> addRoutineHistory({
    required Routine routine,
    DateTime? completedAt,
  }) async {
    final userId = _userId;
    final docRef = _routineHistoryCollection.doc();
    final timestamp = completedAt ?? DateTime.now();
    await docRef.set({
      'id': docRef.id,
      'userId': userId,
      'routineId': routine.id,
      'routineTitle': routine.title,
      'completedAt': Timestamp.fromDate(timestamp),
      'steps': routine.steps,
    });
  }

  Future<void> addGoal(Goal goal) async {
    final userId = _userId;
    final docRef = goal.id.isNotEmpty
        ? _goalsCollection.doc(goal.id)
        : _goalsCollection.doc();
    final data = goal.toMap()
      ..['id'] = docRef.id
      ..['userId'] = userId;
    await docRef.set(data);
  }

  Stream<List<Goal>> watchGoals() {
    final userId = _userId;
    return _goalsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Goal.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> updateGoalMilestones({
    required Goal goal,
  }) async {
    if (goal.id.isEmpty) {
      throw StateError('Goal sem ID não pode ser atualizado.');
    }

    await _goalsCollection.doc(goal.id).update({
      'milestones':
          goal.milestones.map((milestone) => milestone.toMap()).toList(),
    });
  }
}
