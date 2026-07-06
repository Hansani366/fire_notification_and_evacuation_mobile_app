import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// The uppercase tracked section header (`.applabel`), optionally with a
/// trailing count on the right (e.g. "ZONES … 7").
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: AppText.sectionLabel),
          if (trailing != null)
            Text(trailing!.toUpperCase(), style: AppText.sectionLabel),
        ],
      ),
    );
  }
}
