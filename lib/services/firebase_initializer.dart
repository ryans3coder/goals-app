import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

abstract class FirebaseInitializationService {
  Future<void> ensureInitialized();
  bool get isInitialized;
}

class FirebaseInitializer implements FirebaseInitializationService {
  FirebaseInitializer({
    Future<FirebaseApp> Function()? initializeApp,
  }) : _initializeApp = initializeApp ??
            (() => Firebase.initializeApp(
                  options: DefaultFirebaseOptions.currentPlatform,
                ));

  final Future<FirebaseApp> Function() _initializeApp;
  Future<void>? _initializing;

  @override
  bool get isInitialized => Firebase.apps.isNotEmpty;

  @override
  Future<void> ensureInitialized() {
    if (isInitialized) {
      return Future.value();
    }
    if (_initializing != null) {
      return _initializing!;
    }
    _initializing = _initializeApp().then((_) {}).catchError((error) {
      _initializing = null;
      throw error;
    });
    return _initializing!;
  }
}
