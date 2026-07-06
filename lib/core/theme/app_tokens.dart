import 'package:flutter/material.dart';

/// Raw design tokens transcribed from `App_design_v5.html` (`:root`, light theme).
///
/// Material's [ColorScheme] carries the roles Material widgets consume
/// (see `app_theme.dart`); everything M3 has no slot for — the semantic
/// bg/ink triples (incl. `warn`), brand, gradients, shadows, floor-plan
/// colors — lives here as plain consts.
class AppColors {
  AppColors._();

  // Surfaces
  static const bg = Color(0xFFF6F7F9);
  static const card = Color(0xFFFFFFFF);

  // Ink (text)
  static const ink = Color(0xFF12151C);
  static const ink2 = Color(0xFF5A6472);
  static const ink3 = Color(0xFF8A94A3);
  static const inkStrong = Color(0xFF12151C); // btn-primary fill
  static const line = Color(0xFFE7EAEF);
  static const outline = Color(0xFFC2CAD4); // plan / wall strokes

  // Brand
  static const brand = Color(0xFFFF5A3C);
  static const brandLight = Color(0xFFFF7A50);

  // Safe (green)
  static const safe = Color(0xFF16A34A);
  static const safeBg = Color(0xFFE7F6EC);
  static const safeInk = Color(0xFF0F7A38);

  // Warn (amber) — no native M3 role, lives only here
  static const warn = Color(0xFFF59E0B);
  static const warnBg = Color(0xFFFEF4E2);
  static const warnInk = Color(0xFFB4740A);

  // Danger (red)
  static const danger = Color(0xFFE5342A);
  static const dangerBg = Color(0xFFFDEBEA);
  static const dangerInk = Color(0xFFC0261D);
  static const dangerDeep = Color(0xFFB21F16); // detection-panel gradient end

  // Trust badge (blue)
  static const trustBg = Color(0xFFEAF4FF);
  static const trustInk = Color(0xFF1E5DAE);
  static const trustLine = Color(0xFFCFE3FA);

  // Neutral chip / badge
  static const neutralBg = Color(0xFFEEF1F5);

  // Floor-plan palette
  static const planBg = Color(0xFFF1F4F8);
  static const planRoom = Color(0xFFFFFFFF);
  static const planRoomStroke = Color(0xFFD8DEE7);
  static const planWalkway = Color(0xFFEAF0F7);
  static const planGuide = Color(0xFFBFC8D4);
  static const planDoor = Color(0xFF111418);
  static const planBlocked = Color(0xFFCBD2DC);
  static const you = Color(0xFF2563EB); // "YOU" marker

  // Lock-screen glass notification tints
  static const lockGlass = Color(0xB31E222C); // rgba(30,34,44,.72)

  /// Base color for elevation shadows: rgba(16,22,35,…).
  static const _shadowBase = Color(0xFF101623);
  static Color shadowAlpha(double a) =>
      _shadowBase.withValues(alpha: a);
}

/// Corner radii from the design (`--r`, `--rlg`, tile, pill).
class AppRadii {
  AppRadii._();

  static const double r = 18; // cards, zones
  static const double rlg = 24; // hero / large cards
  static const double tile = 15; // status tiles
  static const double sm = 14; // small cards / ai-desc
  static const double pill = 100; // chips + buttons (stadium)

  static const card = BorderRadius.all(Radius.circular(r));
  static const large = BorderRadius.all(Radius.circular(rlg));
  static const small = BorderRadius.all(Radius.circular(sm));
  static const stadium = BorderRadius.all(Radius.circular(pill));
}

/// Elevation shadows. CSS `box-shadow: 0 Ypx Bpx rgba(...)` maps to
/// `BoxShadow(offset: Offset(0, Y), blurRadius: B, color: …)`.
class AppShadows {
  AppShadows._();

  /// `--shadow`: subtle two-layer card shadow.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A101623), // rgba(16,22,35,.04)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0F101623), // rgba(16,22,35,.06)
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// `--shadow-lg`.
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x24101623), // rgba(16,22,35,.14)
      offset: Offset(0, 8),
      blurRadius: 40,
    ),
  ];

  static const List<BoxShadow> danger = [
    BoxShadow(
      color: Color(0x52E5342A), // rgba(229,52,42,.32)
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> brand = [
    BoxShadow(
      color: Color(0x4DFF5A3C), // rgba(255,90,60,.30)
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> detectionPanel = [
    BoxShadow(
      color: Color(0x57E5342A), // rgba(229,52,42,.34)
      offset: Offset(0, 12),
      blurRadius: 34,
    ),
  ];

  static const List<BoxShadow> safeGlow = [
    BoxShadow(
      color: Color(0x5C16A34A), // rgba(22,163,74,.36)
      offset: Offset(0, 16),
      blurRadius: 40,
    ),
  ];
}

/// Linear gradients from the design. CSS angles are approximated with
/// begin/end alignments (exact degrees aren't visually critical here).
class AppGradients {
  AppGradients._();

  /// `linear-gradient(140deg,#FF7A50,#FF5A3C)` — brand button / logo.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandLight, AppColors.brand],
  );

  /// `linear-gradient(155deg,#E5342A,#B21F16)` — detection panel.
  static const detectionPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.danger, AppColors.dangerDeep],
  );

  /// `linear-gradient(150deg,#DFF4E7,#EAF8F0)` — safe hero card.
  static const heroSafe = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDFF4E7), Color(0xFFEAF8F0)],
  );
  static const heroSafeBorder = Color(0xFFC6EAD3);

  /// `linear-gradient(200deg,#141821,#1e2330 60%,#2a2015)` — lock screen.
  static const lock = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF141821), Color(0xFF1E2330), Color(0xFF2A2015)],
    stops: [0.0, 0.6, 1.0],
  );

  /// `linear-gradient(170deg,#DFF4E7,var(--bg) 46%)` — resolved screen.
  static const resolved = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDFF4E7), AppColors.bg],
    stops: [0.0, 0.46],
  );
}
