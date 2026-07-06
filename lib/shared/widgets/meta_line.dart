import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// One cell in a [MetaLine].
class MetaItem {
  const MetaItem(this.label, this.value, {this.isRed = false, this.small = false});

  final String label;
  final String value;
  final bool isRed;

  /// Render the value at a smaller size (e.g. "By user").
  final bool small;
}

/// The 3-up stat strip (`.metaline` / `.rmeta`): a row of bordered tiles, each
/// a small uppercase label over a bold value.
class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.items});

  final List<MetaItem> items;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _Cell(items[i])),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.item);

  final MetaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(Radius.circular(13)),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppText.inter(10.5, 600, color: AppColors.ink3, letterSpacing: 0.6),
          ),
          const SizedBox(height: 3),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: AppText.statValue.copyWith(
              fontSize: item.small ? 14 : 19,
              color: item.isRed ? AppColors.danger : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
