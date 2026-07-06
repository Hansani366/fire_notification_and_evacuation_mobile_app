import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../util/format.dart';
import 'status_chip.dart';
import 'zone_glyphs.dart';

/// Visual treatment derived from a [ZoneStatus].
class _StatusStyle {
  const _StatusStyle(this.tileBg, this.glyph, this.tone, this.dot, this.dotIcon,
      this.border, this.shadow);
  final Color tileBg;
  final Color glyph;
  final ChipTone tone;
  final Color dot;
  final IconData dotIcon;
  final Color border;
  final List<BoxShadow>? shadow;

  static _StatusStyle of(ZoneStatus s) => switch (s) {
        ZoneStatus.clear => const _StatusStyle(
            AppColors.safeBg,
            AppColors.safe,
            ChipTone.clear,
            AppColors.safe,
            Icons.check_rounded,
            AppColors.line,
            null,
          ),
        ZoneStatus.smoke => const _StatusStyle(
            AppColors.warnBg,
            AppColors.warn,
            ChipTone.smoke,
            AppColors.warn,
            Icons.priority_high_rounded,
            Color(0xFFF6D79A),
            null,
          ),
        ZoneStatus.fire => _StatusStyle(
            AppColors.dangerBg,
            AppColors.danger,
            ChipTone.fire,
            AppColors.danger,
            Icons.priority_high_rounded,
            const Color(0xFFF5B8B3),
            [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.14),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
      };
}

/// A tappable zone row on the dashboard (`.zone`): a state-tinted glyph tile
/// with a status dot, the zone name + status chip, its detector, and last scan.
class ZoneCard extends StatelessWidget {
  const ZoneCard({super.key, required this.zone, this.onTap});

  final Zone zone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = _StatusStyle.of(zone.status);
    return Material(
      color: AppColors.card,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadii.card,
            border: Border.all(color: s.border),
            boxShadow: s.shadow,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Tile(glyph: zone.glyph, style: s),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            zone.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        StatusChip(
                          label: zone.status.label,
                          tone: s.tone,
                          size: ChipSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${zone.floor} · ${zone.detectorId}',
                      style: AppText.inter(12, 400, color: AppColors.ink3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scannedAgo(zone.lastScanAt),
                      style: AppText.inter(11.5, 400, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.glyph, required this.style});

  final ZoneGlyph glyph;
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: style.tileBg,
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Center(
              child: ZoneGlyphIcon(glyph: glyph, size: 28, color: style.glyph),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.dot,
                border: Border.all(color: AppColors.card, width: 3),
              ),
              child: Icon(style.dotIcon, size: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
