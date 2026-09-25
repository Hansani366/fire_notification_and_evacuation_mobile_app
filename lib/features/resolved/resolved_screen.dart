import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../shared/widgets/flame_icon.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/surface_card.dart';

/// Flow A end state: the user is accounted for at the muster point, while the
/// incident stays active for anyone still inside.
class ResolvedScreen extends StatelessWidget {
  const ResolvedScreen({super.key});

  void _callEmergency(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency services'),
        content: const Text('Dialing fire & rescue service…'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = RepositoryScope.of(context).activeIncident;
    final muster = incident.muster;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.resolved),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: BackLabelButton(
                      label: 'Site status',
                      onTap: () => context.go('/dashboard'),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _ResCheck(),
                            const SizedBox(height: 22),
                            Text(
                              "You're marked safe",
                              textAlign: TextAlign.center,
                              style: AppText.heroTitle
                                  .copyWith(color: AppColors.safeInk),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your floor team knows you\'re out at the muster '
                              'point. The ${incident.zone.name} incident stays '
                              'active for anyone still inside — keep clear until '
                              'fire & rescue confirm all clear.',
                              textAlign: TextAlign.center,
                              style: AppText.inter(15, 400,
                                  color: AppColors.ink2, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            SurfaceCard(
                              padding: EdgeInsets.zero,
                              clip: true,
                              child: Column(
                                children: [
                                  _StatusRow(
                                    bg: AppColors.dangerBg,
                                    fg: AppColors.danger,
                                    icon: const FlameIcon(
                                        size: 18, color: AppColors.danger),
                                    title: '${incident.zone.name} · still active',
                                    // No percentage: a sensor-raised alarm
                                    // carries 0.0 by design, and this line is
                                    // read after someone has already evacuated
                                    // on the strength of it.
                                    subtitle: 'Fire & rescue notified',
                                    divider: true,
                                  ),
                                  _StatusRow(
                                    bg: AppColors.safeBg,
                                    fg: AppColors.safe,
                                    icon: const Icon(Icons.person_outline,
                                        size: 18, color: AppColors.safe),
                                    title:
                                        'Muster roll · ${muster.present} of ${muster.total}',
                                    subtitle:
                                        '${muster.missing} workers not yet checked in',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            PillButton(
                              label: 'Call emergency services',
                              variant: PillVariant.danger,
                              onPressed: () => _callEmergency(context),
                            ),
                            const SizedBox(height: 10),
                            PillButton(
                              label: 'View route again',
                              variant: PillVariant.ghost,
                              onPressed: () => context.pushReplacement('/incident'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

/// The big green check with a one-shot "pop" on entry.
class _ResCheck extends StatefulWidget {
  const _ResCheck();

  @override
  State<_ResCheck> createState() => _ResCheckState();
}

class _ResCheckState extends State<_ResCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
        .disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      child: Container(
        width: 110,
        height: 110,
        decoration: const BoxDecoration(
          color: AppColors.safe,
          shape: BoxShape.circle,
          boxShadow: AppShadows.safeGlow,
        ),
        child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.divider = false,
  });

  final Color bg;
  final Color fg;
  final Widget icon;
  final String title;
  final String subtitle;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: AppText.pjs(14.5, 600, color: AppColors.ink)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: AppText.inter(12, 400, color: AppColors.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
