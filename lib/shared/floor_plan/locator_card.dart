import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/surface_card.dart';
import 'floor_plan_data.dart';
import 'floor_plan_view.dart';

class LegendItem {
  const LegendItem(this.color, this.label);
  final Color color;
  final String label;
}

/// A card wrapping the [FloorPlanView] with an optional small header and a
/// swatch legend beneath a dashed divider (`.locwrap` + `.legend`).
class LocatorCard extends StatelessWidget {
  const LocatorCard({
    super.key,
    required this.mode,
    this.header,
    this.legend = const [],
  });

  final FloorPlanMode mode;
  final String? header;
  final List<LegendItem> legend;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 12, color: AppColors.ink3),
                const SizedBox(width: 6),
                Text(header!.toUpperCase(), style: AppText.quietLabel),
              ],
            ),
            const SizedBox(height: 10),
          ],
          FloorPlanView(mode: mode),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DashedDivider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final item in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: const BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        item.label,
                        style: AppText.inter(12, 500, color: AppColors.ink2),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedDividerPainter()),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(_DashedDividerPainter oldDelegate) => false;
}
