import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/data_provider.dart';
import 'services/remote_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseInitialization = Firebase.initializeApp();
  firebaseInitialization.catchError(
    (error) => debugPrint('Falha ao inicializar o Firebase: $error'),
  );
  runApp(NeuroSyncApp(firebaseInitialization: firebaseInitialization));
}

class NeuroSyncApp extends StatelessWidget {
  const NeuroSyncApp({super.key, required this.firebaseInitialization});

  final Future<void> firebaseInitialization;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(
            firebaseInitialization: firebaseInitialization,
          ),
        ),
        Provider<RemoteSyncService>(
          create: (context) => FirebaseRemoteSyncService(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<DataProvider>(
          create: (context) => DataProvider(
            remoteSync: context.read<RemoteSyncService>(),
          ),
        ),
        StreamProvider<firebase_auth.User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const StartupGate(),
      ),
    );
  }
}

class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data ?? false) {
          return const MainScreen();
        }

        return const OnboardingScreen();
      },
    );
  }

  Future<bool> _hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('hasSeenOnboarding') ?? false;
  }
}
