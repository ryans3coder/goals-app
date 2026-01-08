import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0B1020);
  static const Color surfaceDark = Color(0xFF121A33);
  static const Color primary = Color(0xFF6D5EF6);
  static const Color accent = AppColors.primary;
  static const Color secondary = Color(0xFFB8FF3C);
  static const Color info = Color(0xFF4DB5FF);
  static const Color danger = AppColors.primary;
  static const Color textTitle = Color(0xFF1A1C29);
  static const Color textBody = Color(0xFF525766);
  static const Color textDark = Color(0xFFEAF0FF);
  static const Color outline = Color(0x1F525766);
}

class AppDarkColors {
  static const Color background = AppColors.backgroundDark;
  static const Color surface = AppColors.surfaceDark;
  static const Color text = AppColors.textDark;
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color info = AppColors.info;
}

class AppRadii {
  static const double input = 16;
  static const double card = 24;
  static const double pill = 999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double card = 20;
  static const double page = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double buttonHeight = 56;
}

class AppSizes {
  static const double iconHero = 96;
  static const double iconEmptyState = 80;
  static const double iconSmall = 18;
  static const double iconNav = 24;
  static const double iconFab = 32;
  static const double navBarHeight = 72;
  static const double indicatorActive = 20;
  static const double indicator = 8;
  static const double progressHeight = 8;
}

class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final manrope = GoogleFonts.manropeTextTheme(base);
    return manrope.copyWith(
      displayLarge: manrope.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium:
          manrope.displayMedium?.copyWith(fontWeight: FontWeight.w800),
      displaySmall: manrope.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineLarge:
          manrope.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium:
          manrope.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall:
          manrope.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: manrope.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: manrope.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      titleSmall: manrope.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      bodyLarge: manrope.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: manrope.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: manrope.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: manrope.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: manrope.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      labelSmall: manrope.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class AppShadows {
  static final BoxShadow cardShadow = BoxShadow(
    color: AppColors.primary.withValues(alpha: 0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    );
    final textTheme = AppTypography.textTheme(baseTheme.textTheme).apply(
      bodyColor: AppColors.textBody,
      displayColor: AppColors.textTitle,
    );
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textTitle,
      surface: AppColors.surface,
      onSurface: AppColors.textTitle,
      background: AppColors.background,
      error: AppColors.primary,
      onError: Colors.white,
    ).copyWith(
      outline: AppColors.textBody.withValues(alpha: 0.12),
      tertiary: AppColors.info,
    );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: AppColors.primary),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppShadows.cardShadow.color,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
        bodySmall: textTheme.bodySmall?.copyWith(color: AppColors.textBody),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textTitle,
        iconTheme: const IconThemeData(color: AppColors.primary),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textTitle,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        disabledColor: colorScheme.outline,
        labelStyle: textTheme.bodySmall?.copyWith(color: AppColors.textBody),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textTitle,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: colorScheme.outline, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: colorScheme.outline,
        circularTrackColor: colorScheme.outline,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textBody,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBarHeight,
        indicatorColor: AppColors.primary.withOpacity(0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.iconNav,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textBody,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.textBody,
              ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textBody,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textBody,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textTitle,
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xl,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.info,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textTitle,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );
    final textTheme = AppTypography.textTheme(baseTheme.textTheme).apply(
      bodyColor: AppDarkColors.text,
      displayColor: AppDarkColors.text,
    );
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppDarkColors.primary,
      onPrimary: Colors.white,
      secondary: AppDarkColors.secondary,
      onSecondary: AppColors.textTitle,
      surface: AppDarkColors.surface,
      onSurface: AppDarkColors.text,
      background: AppDarkColors.background,
      error: AppDarkColors.primary,
      onError: Colors.white,
    ).copyWith(
      outline: AppDarkColors.text.withValues(alpha: 0.16),
      tertiary: AppDarkColors.info,
    );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDarkColors.background,
      iconTheme: const IconThemeData(color: AppColors.primary),
      cardTheme: CardThemeData(
        color: AppDarkColors.surface,
        elevation: 2,
        shadowColor: AppShadows.cardShadow.color,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppDarkColors.background,
        foregroundColor: AppDarkColors.text,
        iconTheme: const IconThemeData(color: AppColors.primary),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppDarkColors.surface,
        selectedColor: AppDarkColors.primary.withValues(alpha: 0.3),
        disabledColor: colorScheme.outline,
        labelStyle: textTheme.bodySmall,
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppDarkColors.text,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppDarkColors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: colorScheme.outline, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppDarkColors.primary,
        linearTrackColor: colorScheme.outline,
        circularTrackColor: colorScheme.outline,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppDarkColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDarkColors.surface,
        selectedItemColor: AppDarkColors.primary,
        unselectedItemColor: AppDarkColors.text,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBarHeight,
        indicatorColor: AppDarkColors.primary.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.iconNav,
            color: states.contains(WidgetState.selected)
                ? AppDarkColors.primary
                : AppDarkColors.text,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: states.contains(WidgetState.selected)
                    ? AppDarkColors.primary
                    : AppDarkColors.text,
              ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDarkColors.surface,
        modalBackgroundColor: AppDarkColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.text,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.text,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppDarkColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppDarkColors.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDarkColors.text,
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xl,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDarkColors.info,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const StadiumBorder(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppDarkColors.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppDarkColors.text,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}
