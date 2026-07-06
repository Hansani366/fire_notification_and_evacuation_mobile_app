import 'package:flutter/widgets.dart';

/// Responsive constants. The app is "phones-centered": it flows fluidly across
/// all phone widths, and on anything wider than a phone it simply caps the
/// content to a comfortable column and centers it (no rail / no two-pane).
class Breakpoints {
  Breakpoints._();

  /// Below this width we treat the device as a phone (M3 "compact").
  static const double compact = 600;

  /// Max width for normal scrolling content on large screens.
  static const double contentMaxWidth = 500;

  /// Max width for full-screen "takeover" panels (lock / incident / resolved).
  static const double takeoverMaxWidth = 440;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;
}
