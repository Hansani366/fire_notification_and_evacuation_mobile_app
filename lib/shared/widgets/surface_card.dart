import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The standard white rounded card used throughout (`.card` / `.locwrap` /
/// `.flowcard`): surface fill, hairline border, soft shadow. Set [onTap] to make
/// it tappable with a matching ink ripple.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadii.card,
    this.shadow = AppShadows.card,
    this.color = AppColors.card,
    this.border,
    this.onTap,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final List<BoxShadow>? shadow;
  final Color color;
  final Border? border;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      borderRadius: radius,
      border: border ?? Border.all(color: AppColors.line),
      boxShadow: shadow,
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        padding: padding,
        child: child,
      );
    }

    return Material(
      color: color,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: decoration,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
