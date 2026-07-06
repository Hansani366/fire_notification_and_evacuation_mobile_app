import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// The five button treatments from the prototype. Material's own button types
/// don't map 1:1 onto these colour variants, so this is a thin custom pill
/// (min-height 48, press-scale, colored shadows where the design has them).
enum PillVariant { primary, danger, safe, ghost, brand }

class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color? bg, Gradient? gradient, List<BoxShadow>? shadow,
            Border? border) =
        switch (widget.variant) {
      PillVariant.primary => (Colors.white, AppColors.inkStrong, null, null, null),
      PillVariant.danger => (
          Colors.white,
          AppColors.danger,
          null,
          AppShadows.danger,
          null,
        ),
      PillVariant.safe => (Colors.white, AppColors.safe, null, null, null),
      PillVariant.ghost => (
          AppColors.ink,
          AppColors.card,
          null,
          null,
          Border.all(color: AppColors.line, width: 1.5),
        ),
      PillVariant.brand => (
          Colors.white,
          null,
          AppGradients.brand,
          AppShadows.brand,
          null,
        ),
    };

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: AppRadii.stadium,
          boxShadow: shadow,
          border: border,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadii.stadium,
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              width: widget.expand ? double.infinity : null,
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: fg),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: AppText.buttonLabel.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
