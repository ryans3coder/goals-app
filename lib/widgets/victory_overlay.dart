import 'dart:async';

import 'package:flutter/material.dart';

import '../models/feedback_preferences.dart';
import '../services/feedback_manager.dart';
import '../theme/app_theme.dart';

class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    super.key,
    required this.message,
    required this.preferences,
    required this.feedbackManager,
    required this.onDismiss,
    this.displayDuration = const Duration(milliseconds: 1200),
  });

  final String message;
  final FeedbackPreferences preferences;
  final FeedbackManager feedbackManager;
  final Duration displayDuration;
  final VoidCallback onDismiss;

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  bool _dismissed = false;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _triggerFeedback();
    _startDismissTimer();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _triggerFeedback() {
    widget.feedbackManager.triggerVictoryFeedback(
      widget.preferences,
      forceVisual: true,
    );
    if (widget.preferences.animationsEnabled) {
      _animationController.forward();
    } else {
      _animationController.value = 1;
    }
  }

  void _startDismissTimer() {
    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    if (!mounted) {
      return;
    }
    widget.onDismiss();
  }

  void _handleTap() {
    _dismissTimer?.cancel();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      child: InkWell(
        onTap: _handleTap,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
