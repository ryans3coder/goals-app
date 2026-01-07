import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/backup_controller.dart';
import '../services/backup_local_gateway.dart';
import '../services/backup_remote_store.dart';
import '../services/data_provider.dart';
import '../services/firebase_initializer.dart';
import '../services/local_data_store.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final BackupController _controller;
  late final BackupAuthService _authService;

  @override
  void initState() {
    super.initState();
    final firebaseInitializer = context.read<FirebaseInitializationService>();
    _authService = context.read<AuthService>();
    _controller = BackupController(
      firebaseInitializer: firebaseInitializer,
      authService: _authService,
      remoteStore: context.read<BackupRemoteStore>(),
      localGateway: DataProviderBackupGateway(
        dataProvider: context.read<DataProvider>(),
      ),
      localStore: context.read<LocalDataStore>(),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.backupTitle),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              if (_controller.status == BackupUiStatus.loading)
                _buildLoadingCard(context),
              if (_controller.status == BackupUiStatus.error)
                _buildErrorCard(context),
              if (_controller.errorMessage != null &&
                  _controller.status != BackupUiStatus.error)
                _buildInlineError(context),
              if (_controller.status == BackupUiStatus.ready)
                _buildReadyContent(context),
              if (_controller.status != BackupUiStatus.ready)
                _buildOfflineContent(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            AppStrings.backupLoading,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _controller.errorMessage ?? AppStrings.backupInitError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: AppStrings.retry,
            icon: const Icon(Icons.refresh),
            onPressed: _controller.isWorking ? null : _controller.retry,
            isLoading: _controller.isWorking,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _controller.errorMessage ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyContent(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Column(
          children: [
            _buildLoginCard(context, user, snapshot.connectionState),
            const SizedBox(height: AppSpacing.lg),
            _buildLastBackupCard(context),
            const SizedBox(height: AppSpacing.lg),
            _buildActionsCard(context, user),
          ],
        );
      },
    );
  }

  Widget _buildOfflineContent(BuildContext context) {
    return Column(
      children: [
        _buildLastBackupCard(context),
        const SizedBox(height: AppSpacing.lg),
        _buildActionsCard(context, null),
      ],
    );
  }

  Widget _buildLoginCard(
    BuildContext context,
    firebase_auth.User? user,
    ConnectionState connectionState,
  ) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.backupLoginStatusTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (connectionState == ConnectionState.waiting)
            Row(
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(AppStrings.backupCheckingLogin),
              ],
            )
          else if (user == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.backupLoggedOut,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: AppStrings.signInGoogle,
                  icon: const Icon(Icons.login),
                  onPressed: _controller.isWorking ? null : _handleSignIn,
                  isLoading: _controller.isWorking,
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? AppStrings.backupLoggedIn,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email ?? AppStrings.backupNoEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSecondaryButton(
                  label: AppStrings.signOut,
                  icon: const Icon(Icons.logout),
                  onPressed: _controller.isWorking ? null : _handleSignOut,
                  isLoading: _controller.isWorking,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLastBackupCard(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.backupLastTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatTimestamp(_controller.lastBackupAt),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    firebase_auth.User? user,
  ) {
    final theme = Theme.of(context);
    final enabled = _controller.status == BackupUiStatus.ready && user != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.backupActionsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.backupActionsHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: AppStrings.backupNowAction,
            icon: const Icon(Icons.cloud_upload),
            onPressed: enabled && !_controller.isWorking ? _handleBackup : null,
            isLoading: _controller.isWorking,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: AppStrings.restoreAction,
            icon: const Icon(Icons.cloud_download),
            onPressed:
                enabled && !_controller.isWorking ? _handleRestore : null,
            isLoading: _controller.isWorking,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn() async {
    try {
      await _authService.signInWithGoogle();
    } on StateError catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack(AppStrings.backupSignInError);
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
  }

  Future<void> _handleBackup() async {
    await _controller.backupNow();
    if (_controller.errorMessage == null && mounted) {
      _showSnack(AppStrings.backupSuccess);
    }
  }

  Future<void> _handleRestore() async {
    final shouldRestore = await _confirmRestore();
    if (!shouldRestore) {
      return;
    }
    final snapshot = await _controller.restoreLatest();
    if (!mounted) {
      return;
    }
    if (snapshot != null && _controller.errorMessage == null) {
      _showSnack(AppStrings.restoreSuccess);
    }
  }

  Future<bool> _confirmRestore() async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.restoreConfirmTitle),
          content: Text(AppStrings.restoreConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppStrings.cancel,
                style: theme.textTheme.labelLarge,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppStrings.restoreConfirmAction,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return AppStrings.backupNever;
    }
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year ${AppStrings.backupAtLabel} $hour:$minute';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
