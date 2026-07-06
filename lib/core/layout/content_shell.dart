import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Wraps a scrolling screen body so it stays a readable, phone-width column:
/// full-bleed on phones, capped + centered on tablets/foldables. Also applies
/// [SafeArea] so content clears the status bar / gesture insets.
class ContentShell extends StatelessWidget {
  const ContentShell({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.top = true,
    this.bottom = true,
  });

  final Widget child;
  final double maxWidth;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
