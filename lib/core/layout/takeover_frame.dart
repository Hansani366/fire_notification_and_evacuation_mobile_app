import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Full-screen "takeover" surface (lock / incident / resolved). The background
/// (gradient or solid) is full-bleed under the system bars, while the content
/// is held to a phone-width column and centered on large screens. Vertical
/// layout inside is left to the child (e.g. a scroll + pinned CTA bar).
class TakeoverFrame extends StatelessWidget {
  const TakeoverFrame({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.maxWidth = Breakpoints.takeoverMaxWidth,
    this.safeTop = true,
    this.safeBottom = true,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final double maxWidth;
  final bool safeTop;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient, color: color),
      child: SafeArea(
        top: safeTop,
        bottom: safeBottom,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
