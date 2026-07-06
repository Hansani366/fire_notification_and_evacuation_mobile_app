import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/flame_icon.dart';

/// The red detection card that replaces a live camera feed (`.detpanel`):
/// detector identity + a confidence bar, over a softly pulsing radial glow.
class DetectionPanel extends StatefulWidget {
  const DetectionPanel({
    super.key,
    required this.zoneName,
    required this.subtitle,
    required this.confidence,
  });

  final String zoneName;
  final String subtitle;
  final double confidence; // 0..1

  @override
  State<DetectionPanel> createState() => _DetectionPanelState();
}

class _DetectionPanelState extends State<DetectionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _glow.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) _glow.stop();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const white90 = Color(0xE6FFFFFF);
    return ClipRRect(
      borderRadius: AppRadii.card,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.detectionPanel,
          borderRadius: AppRadii.card,
          boxShadow: AppShadows.detectionPanel,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, _) {
                  final t = MediaQuery.of(context).disableAnimations
                      ? 0.75
                      : 0.5 + 0.5 * _glow.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.64, -0.64),
                        radius: 0.9,
                        colors: [
                          const Color(0xFFFFB478).withValues(alpha: 0.5 * t),
                          const Color(0x00FFB478),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                        ),
                        child: const Center(
                          child: FlameIcon(size: 30, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.zoneName,
                                style: AppText.detZone.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(widget.subtitle,
                                style: AppText.inter(13, 400, color: white90)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DETECTION CONFIDENCE',
                          style: AppText.pjs(11, 700,
                              color: white90, letterSpacing: 0.66)),
                      Text('${(widget.confidence * 100).round()}%',
                          style: AppText.pjs(11, 700, color: white90)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    child: Container(
                      height: 8,
                      color: Colors.white.withValues(alpha: 0.22),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.confidence.clamp(0.0, 1.0),
                        child: Container(color: Colors.white),
                      ),
                    ),
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
