import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/backup_remote_store.dart';
import 'services/data_provider.dart';
import 'services/firebase_initializer.dart';
import 'services/local_data_store.dart';
import 'services/remote_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeuroSyncApp());
}

class NeuroSyncApp extends StatelessWidget {
  const NeuroSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseInitializationService>(
          create: (_) => FirebaseInitializer(),
        ),
        Provider<LocalDataStore>(
          create: (_) => LocalDataStore(),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            firebaseInitializer: context.read<FirebaseInitializationService>(),
          ),
        ),
        Provider<BackupRemoteStore>(
          create: (context) => FirebaseBackupRemoteStore(
            firebaseInitializer: context.read<FirebaseInitializationService>(),
          ),
        ),
        Provider<RemoteSyncService>(
          create: (context) => FirebaseRemoteSyncService(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<DataProvider>(
          create: (context) => DataProvider(
            localStore: context.read<LocalDataStore>(),
            remoteSync: context.read<RemoteSyncService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
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
