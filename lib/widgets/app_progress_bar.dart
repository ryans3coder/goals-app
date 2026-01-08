import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.input),
      child: LinearProgressIndicator(
        value: value,
        minHeight: AppSizes.progressHeight,
        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        color: theme.colorScheme.primary,
      ),
    );
  }
}
