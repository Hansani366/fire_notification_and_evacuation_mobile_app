import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'app_typography.dart';

/// Single light [ThemeData] for the app. (Dark mode is intentionally out of
/// scope — see the plan. If it returns, split this into light/dark builders and
/// promote [AppColors] into a `ThemeExtension`.)
class AppTheme {
  AppTheme._();

  static final ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.brand,
    onPrimary: Colors.white,
    secondary: AppColors.brand,
    onSecondary: Colors.white,
    tertiary: AppColors.safe,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.safeBg,
    onTertiaryContainer: AppColors.safeInk,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerBg,
    onErrorContainer: AppColors.dangerInk,
    surface: AppColors.card,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.ink2,
    outline: AppColors.outline,
    outlineVariant: AppColors.line,
    surfaceTint: Colors.transparent, // keep cards pure white (no M3 tint)
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Inter',
      textTheme: AppText.textTheme,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.card,
        elevation: 0,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.ink3,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.navLabel.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.ink3,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
