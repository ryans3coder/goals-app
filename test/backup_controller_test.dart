import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/backup_snapshot.dart';
import 'package:flutter_application_1/services/backup_controller.dart';
import 'package:flutter_application_1/services/backup_remote_store.dart';
import 'package:flutter_application_1/services/firebase_initializer.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class FakeFirebaseInitializer implements FirebaseInitializationService {
  FakeFirebaseInitializer({required this.failuresBeforeSuccess});

  final int failuresBeforeSuccess;
  int attempts = 0;
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> ensureInitialized() async {
    attempts += 1;
    if (attempts <= failuresBeforeSuccess) {
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'unavailable',
        message: 'Sem conexão',
      );
    }
    _isInitialized = true;
  }
}

class FakeAuthService implements BackupAuthService {
  @override
  firebase_auth.User? get currentUser => null;

  @override
  Stream<firebase_auth.User?> get authStateChanges => Stream.value(null);

  @override
  Future<firebase_auth.UserCredential> signInWithGoogle() {
    throw StateError('Não implementado');
  }

  @override
  Future<void> signOut() async {}
}

class FakeRemoteStore implements BackupRemoteStore {
  @override
  Future<BackupSnapshot?> fetchLatestSnapshot({
    required String userId,
  }) async {
    return null;
  }

  @override
  Future<void> uploadSnapshot({
    required String userId,
    required BackupSnapshot snapshot,
  }) async {}
}

class FakeLocalGateway implements BackupLocalGateway {
  @override
  Future<BackupSnapshot> buildSnapshot() async {
    throw StateError('Não implementado');
  }

  @override
  Future<void> restoreSnapshot(BackupSnapshot snapshot) async {}
}

void main() {
  test(
    'backup controller handles init failure and retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      final initializer = FakeFirebaseInitializer(failuresBeforeSuccess: 1);
      final controller = BackupController(
        firebaseInitializer: initializer,
        authService: FakeAuthService(),
        remoteStore: FakeRemoteStore(),
        localGateway: FakeLocalGateway(),
        localStore: LocalDataStore(),
      );

      await controller.initialize();

      expect(controller.status, BackupUiStatus.error);
      expect(controller.errorMessage, 'Sem conexão com a internet.');

      await controller.retry();

      expect(controller.status, BackupUiStatus.ready);
      expect(controller.errorMessage, isNull);
      expect(initializer.attempts, 2);
    },
  );
}
