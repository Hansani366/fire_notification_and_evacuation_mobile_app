import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/flame_icon.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/surface_card.dart';

/// One row in the history log (`.evt`): a type tile, the event title with a
/// zone chip, its time/duration meta, and a resolution badge.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap});

  final HistoryEvent event;
  final VoidCallback? onTap;

  bool get _isFire =>
      event.type == DetectionType.fire || event.type == DetectionType.both;

  @override
  Widget build(BuildContext context) {
    final tileBg = _isFire ? AppColors.dangerBg : AppColors.warnBg;
    final tileFg = _isFire ? AppColors.danger : AppColors.warn;
    final emoji = _isFire ? '🔥' : '⚠️';

    return SurfaceCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: const BorderRadius.all(Radius.circular(13)),
            ),
            child: Center(
              child: _isFire
                  ? FlameIcon(size: 24, color: tileFg)
                  : Icon(Icons.cloud_outlined, size: 24, color: tileFg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('$emoji ${event.type.label}', style: AppText.rowTitle),
                    const SizedBox(width: 7),
                    Flexible(
                      child: StatusChip(
                        label: event.zoneName,
                        tone: _isFire ? ChipTone.fire : ChipTone.smoke,
                        size: ChipSize.mini,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.inter(12, 400, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Badge(event.resolution),
        ],
      ),
    );
  }

  String get _meta {
    final base = '${event.whenLabel} · ${event.durationMin} min · ${event.floor}';
    return event.cause == null ? base : '$base · ${event.cause}';
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.resolution);

  final Resolution resolution;

  @override
  Widget build(BuildContext context) {
    final tone = switch (resolution) {
      Resolution.userConfirmed => ChipTone.fire,
      Resolution.autoCleared => ChipTone.neutral,
      Resolution.falseAlarm => ChipTone.clear,
    };
    return StatusChip(
      label: resolution.label,
      tone: tone,
      size: ChipSize.small,
    );
  }
}
