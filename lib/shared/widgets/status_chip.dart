import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Colour treatment for a chip.
enum ChipTone {
  clear(AppColors.safeBg, AppColors.safeInk),
  smoke(AppColors.warnBg, AppColors.warnInk),
  fire(AppColors.dangerBg, AppColors.dangerInk),
  neutral(AppColors.neutralBg, AppColors.ink2);

  const ChipTone(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

enum ChipSize { normal, small, mini }

/// A rounded status pill (`.chip` in the prototype): "Clear", "Smoke", "Fire",
/// or a neutral zone/name tag.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.clear,
    this.size = ChipSize.normal,
    this.leading,
  });

  final String label;
  final ChipTone tone;
  final ChipSize size;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final (double fontSize, EdgeInsets pad, double gap) = switch (size) {
      ChipSize.normal => (12, const EdgeInsets.fromLTRB(11, 5, 11, 5), 6),
      ChipSize.small => (10, const EdgeInsets.fromLTRB(8, 3, 8, 3), 4),
      ChipSize.mini => (9, const EdgeInsets.fromLTRB(7, 2, 7, 2), 4),
    };

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: AppRadii.stadium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: tone.fg, size: fontSize + 1),
              child: leading!,
            ),
            SizedBox(width: gap),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.chip.copyWith(fontSize: fontSize, color: tone.fg),
            ),
          ),
        ],
      ),
    );
  }
}
