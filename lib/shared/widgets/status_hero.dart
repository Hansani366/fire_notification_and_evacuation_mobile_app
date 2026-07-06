import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// The big rounded gradient status card (`.hero.safe`) — an icon tile, a large
/// title and a subtitle, with a soft radial "pulse ring" bleeding off the
/// top-right corner. Currently the safe (green) treatment used on the dashboard
/// and zone-detail screens.
class StatusHero extends StatelessWidget {
  const StatusHero({
    super.key,
    this.icon = Icons.check_rounded,
    required this.title,
    required this.subtitle,
    this.iconSize = 58,
    this.iconRadius = 18,
    this.titleSize = 30,
  });

  final IconData icon;
  final String title;

  /// Rich subtitle (caller supplies bold spans as needed).
  final Widget subtitle;
  final double iconSize;
  final double iconRadius;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.large,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.heroSafe,
          borderRadius: AppRadii.large,
          border: Border.all(color: AppGradients.heroSafeBorder),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2916A34A), Color(0x0016A34A)],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: AppColors.safe,
                      borderRadius: BorderRadius.circular(iconRadius),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x5216A34A),
                          offset: Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: iconSize * 0.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: AppText.heroTitle
                        .copyWith(fontSize: titleSize, color: AppColors.safeInk),
                  ),
                  const SizedBox(height: 8),
                  DefaultTextStyle.merge(
                    style: AppText.inter(14, 400, color: AppColors.ink2),
                    child: subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
