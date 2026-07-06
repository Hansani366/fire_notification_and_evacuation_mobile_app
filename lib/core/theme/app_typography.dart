import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Type scale transcribed from the prototype.
///
/// Display family = **Plus Jakarta Sans** (headings/labels), body = **Inter**.
/// Both are bundled as *variable* fonts, so weights are pinned with
/// [FontVariation] on the `wght` axis (belt-and-braces with `fontWeight`).
/// CSS `letter-spacing` is in `em`; Flutter wants logical px, so the values
/// below are already multiplied out (e.g. -0.02em @ 42px = -0.84).
class AppText {
  AppText._();

  static const _display = 'Plus Jakarta Sans';
  static const _body = 'Inter';

  static TextStyle _s(
    String family,
    double size,
    int wght, {
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontWeight: FontWeight.values[(wght ~/ 100) - 1],
      fontVariations: [FontVariation('wght', wght.toDouble())],
    );
  }

  static TextStyle pjs(double size, int wght,
          {double? letterSpacing, double? height, Color? color}) =>
      _s(_display, size, wght,
          letterSpacing: letterSpacing, height: height, color: color);

  static TextStyle inter(double size, int wght,
          {double? letterSpacing, double? height, Color? color}) =>
      _s(_body, size, wght,
          letterSpacing: letterSpacing, height: height, color: color);

  // ---- Display / headings ------------------------------------------------
  static final lockClock = pjs(74, 700, letterSpacing: -1.48, height: 1.0);
  static final pageTitle = pjs(42, 800, letterSpacing: -0.84, height: 1.02);
  static final incidentTitle = pjs(34, 800, letterSpacing: -0.68, height: 1.02);
  static final heroTitle = pjs(30, 800, letterSpacing: -0.6, height: 1.0);
  static final sectionTitle = pjs(22, 800, letterSpacing: -0.22); // hi / h2

  // ---- Titles / body -----------------------------------------------------
  static final cardTitle = pjs(15, 700); // znm
  static final rowTitle = pjs(14, 700);
  static final statValue = pjs(19, 800);
  static final detZone = pjs(22, 800);

  static final lede = inter(17, 400, height: 1.45, color: AppColors.ink2);
  static final body = inter(14, 400, height: 1.45);
  static final bodySm = inter(13, 400, height: 1.45);

  // ---- Labels ------------------------------------------------------------
  static final eyebrow = pjs(12, 700,
      letterSpacing: 1.68, height: 1.0, color: AppColors.brand);
  static final sectionLabel = pjs(12, 700,
      letterSpacing: 1.2, color: AppColors.ink3); // applabel
  static final quietLabel = pjs(11, 700,
      letterSpacing: 0.99, color: AppColors.ink3); // ai-desc "q"
  static final chip = pjs(12, 700, height: 1.0);
  static final badge = pjs(10, 700);
  static final navLabel = pjs(10.5, 600);
  static final buttonLabel = pjs(15, 700);
  static final backLabel = pjs(14, 700);
  static final trust = inter(12.5, 600);

  /// The full [TextTheme] handed to [ThemeData]. Screen widgets mostly pull
  /// from the named styles above; this keeps Material's own widgets on-brand.
  static TextTheme get textTheme => TextTheme(
        displayLarge: lockClock,
        displayMedium: pageTitle,
        displaySmall: heroTitle,
        headlineMedium: incidentTitle,
        headlineSmall: heroTitle,
        titleLarge: sectionTitle,
        titleMedium: cardTitle,
        titleSmall: rowTitle,
        bodyLarge: inter(15, 400, height: 1.45),
        bodyMedium: body,
        bodySmall: bodySm,
        labelLarge: buttonLabel,
        labelMedium: chip,
        labelSmall: badge,
      ).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      );
}
