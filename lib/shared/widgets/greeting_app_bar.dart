import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// In-content app bar (`.appbar`): a big title with a smaller subtitle beneath,
/// and an optional trailing widget (round action or a chip).
class GreetingAppBar extends StatelessWidget {
  const GreetingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleWidget,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Optional richer title (e.g. with a leading emoji/flame). Overrides [title].
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget ?? Text(title, style: AppText.sectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppText.inter(12.5, 500, color: AppColors.ink3),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// The 40×40 circular icon action in the app bar (`.round-btn`).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.card,
      shape: CircleBorder(side: BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 19, color: AppColors.ink),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The "‹ Back-label" row used atop detail screens (`.back`).
class BackLabelButton extends StatelessWidget {
  const BackLabelButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.small,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, size: 20, color: AppColors.ink),
              const SizedBox(width: 4),
              Text(label, style: AppText.backLabel),
            ],
          ),
        ),
      ),
    );
  }
}
