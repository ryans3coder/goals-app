import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/backup_snapshot.dart';
import 'auth_service.dart';
import 'backup_remote_store.dart';
import 'firebase_initializer.dart';
import 'local_data_store.dart';

abstract class BackupLocalGateway {
  Future<BackupSnapshot> buildSnapshot();
  Future<void> restoreSnapshot(BackupSnapshot snapshot);
}

enum BackupUiStatus {
  idle,
  loading,
  ready,
  error,
}

class BackupController extends ChangeNotifier {
  BackupController({
    required FirebaseInitializationService firebaseInitializer,
    required BackupAuthService authService,
    required BackupRemoteStore remoteStore,
    required BackupLocalGateway localGateway,
    required LocalDataStore localStore,
  })  : _firebaseInitializer = firebaseInitializer,
        _authService = authService,
        _remoteStore = remoteStore,
        _localGateway = localGateway,
        _localStore = localStore;

  final FirebaseInitializationService _firebaseInitializer;
  final BackupAuthService _authService;
  final BackupRemoteStore _remoteStore;
  final BackupLocalGateway _localGateway;
  final LocalDataStore _localStore;

  BackupUiStatus _status = BackupUiStatus.idle;
  String? _errorMessage;
  DateTime? _lastBackupAt;
  bool _isWorking = false;

  BackupUiStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastBackupAt => _lastBackupAt;
  bool get isWorking => _isWorking;

  Future<void> initialize() async {
    _status = BackupUiStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseInitializer.ensureInitialized();
      _status = BackupUiStatus.ready;
    } catch (error) {
      _status = BackupUiStatus.error;
      _errorMessage = _mapError(error);
    }

    _lastBackupAt = await _localStore.loadLastBackupAt();
    notifyListeners();
  }

  Future<void> retry() => initialize();

  Future<void> backupNow() async {
    if (_isWorking) {
      return;
    }
    _setWorking(true);
    try {
      await _firebaseInitializer.ensureInitialized();
      final user = _authService.currentUser;
      if (user == null) {
        throw StateError('Faça login para fazer backup.');
      }
      final snapshot = await _localGateway.buildSnapshot();
      await _remoteStore.uploadSnapshot(
        userId: user.uid,
        snapshot: snapshot,
      );
      await _localStore.saveLastBackupAt(snapshot.timestamp);
      _lastBackupAt = snapshot.timestamp;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _mapError(error);
    } finally {
      _setWorking(false);
    }
  }

  Future<BackupSnapshot?> restoreLatest() async {
    if (_isWorking) {
      return null;
    }
    _setWorking(true);
    try {
      await _firebaseInitializer.ensureInitialized();
      final user = _authService.currentUser;
      if (user == null) {
        throw StateError('Faça login para restaurar um backup.');
      }
      final snapshot = await _remoteStore.fetchLatestSnapshot(
        userId: user.uid,
      );
      if (snapshot == null) {
        throw StateError('Nenhum backup encontrado.');
      }
      await _localGateway.restoreSnapshot(snapshot);
      _errorMessage = null;
      return snapshot;
    } catch (error) {
      _errorMessage = _mapError(error);
      return null;
    } finally {
      _setWorking(false);
    }
  }

  void _setWorking(bool value) {
    _isWorking = value;
    notifyListeners();
  }

  String _mapError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is TimeoutException) {
      return 'Tempo limite excedido. Tente novamente.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permissões insuficientes para acessar o backup.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Sem conexão com a internet.';
        case 'deadline-exceeded':
          return 'Tempo limite excedido. Tente novamente.';
      }
      return 'Falha ao conectar com o Firebase.';
    }
    return 'Não foi possível completar a operação. Tente novamente.';
  }
}
