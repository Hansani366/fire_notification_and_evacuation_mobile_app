import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';

/// The three system-health tiles beneath the hero (`.health`).
class HealthRow extends StatelessWidget {
  const HealthRow({super.key, required this.stats});

  final List<HealthStat> stats;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _Tile(stats[i])),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.stat);

  final HealthStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stat.ok ? AppColors.safe : AppColors.warn,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.inter(11, 600, color: AppColors.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(stat.value, style: AppText.pjs(14, 700)),
        ],
      ),
    );
  }
}
