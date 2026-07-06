import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// The glassy critical push notification on the lock screen (`.notif`), with a
/// slowly pulsing danger border. Tapping the body opens the incident; the two
/// inline actions are wired separately.
class CriticalNotificationCard extends StatefulWidget {
  const CriticalNotificationCard({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
    required this.onSeeRoute,
    required this.onSafe,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onSeeRoute;
  final VoidCallback onSafe;

  @override
  State<CriticalNotificationCard> createState() =>
      _CriticalNotificationCardState();
}

class _CriticalNotificationCardState extends State<CriticalNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (!_reduceMotion) _pulse.repeat(reverse: true);
  }

  bool get _reduceMotion =>
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const white70 = Color(0xB3FFFFFF);
    const white55 = Color(0x8CFFFFFF);
    const white82 = Color(0xD1FFFFFF);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _reduceMotion ? 0.6 : _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(
              color: const Color(0xFFFF7864).withValues(alpha: 0.35 + 0.5 * t),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 30),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              child: Container(
                color: AppColors.lockGlass,
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.all(Radius.circular(9)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🔥', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'FIREWATCH · NOW',
                          style: AppText.pjs(12, 700,
                              color: white70, letterSpacing: 0.72),
                        ),
                        const Spacer(),
                        Text('Critical',
                            style: AppText.inter(11, 400, color: white55)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.title,
                        style: AppText.pjs(15, 800, color: Colors.white, height: 1.25)),
                    const SizedBox(height: 5),
                    Text(widget.body,
                        style: AppText.inter(13, 400, color: white82, height: 1.4)),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0x1FFFFFFF), height: 1),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: _Action(
                            label: 'See route',
                            color: AppColors.danger,
                            onTap: widget.onSeeRoute,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Action(
                            label: "I'm safe",
                            color: const Color(0x1FFFFFFF),
                            onTap: widget.onSafe,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          child: Text(label, style: AppText.pjs(13, 700, color: Colors.white)),
        ),
      ),
    );
  }
}
