import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/feedback_preferences.dart';

class FeedbackManager {
  const FeedbackManager({this.onPlaySound});

  final Future<void> Function()? onPlaySound;

  Future<void> triggerVictoryFeedback(
    FeedbackPreferences preferences, {
    bool forceVisual = false,
  }) async {
    if (preferences.soundEnabled) {
      if (onPlaySound != null) {
        await onPlaySound!.call();
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    }

    if (preferences.hapticEnabled && _supportsHaptics()) {
      await HapticFeedback.lightImpact();
    }

    if (!preferences.animationsEnabled && !forceVisual) {
      return;
    }
  }

  bool _supportsHaptics() {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }
}
