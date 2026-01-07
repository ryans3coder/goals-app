import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HabitCategoryPalette {
  static const String primary = 'primary';
  static const String secondary = 'secondary';
  static const String accent = 'accent';
  static const String danger = 'danger';

  static const List<String> tokens = [
    primary,
    secondary,
    accent,
    danger,
  ];

  static Color resolveColor(String token) {
    switch (token) {
      case secondary:
        return AppColors.secondary;
      case accent:
        return AppColors.accent;
      case danger:
        return AppColors.danger;
      case primary:
      default:
        return AppColors.primary;
    }
  }
}
