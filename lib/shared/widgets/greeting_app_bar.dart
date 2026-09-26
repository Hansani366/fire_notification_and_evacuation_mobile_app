import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// In-content app bar (`.appbar`): a big title with a smaller subtitle beneath,
/// and an optional trailing widget (e.g. a status chip).
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
