import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/takeover_frame.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../shared/floor_plan/floor_plan_data.dart';
import '../../shared/floor_plan/locator_card.dart';
import '../../shared/util/format.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/meta_line.dart';
import '../../shared/widgets/pill_button.dart';
import 'widgets/detection_panel.dart';

/// Flow A: the confirmed emergency alert — detection panel, plain-English AI
/// read, animated safe route, and evacuation CTAs. No live video.
class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _callEmergency() {
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
    final zone = incident.zone;
    final event = incident.event;
    final elapsed = _now.difference(event.detectedAt);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: TakeoverFrame(
          color: AppColors.bg,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  children: [
                    BackLabelButton(
                      label: 'Site status',
                      onTap: () => context.go('/dashboard'),
                    ),
                    const SizedBox(height: 4),
                    const _IncidentFlag(),
                    const SizedBox(height: 14),
                    Text('🔥 Fire detected', style: AppText.incidentTitle),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: AppText.inter(16, 400, color: AppColors.ink2),
                        children: [
                          TextSpan(
                            text: zone.name,
                            style: AppText.inter(16, 600, color: AppColors.ink),
                          ),
                          TextSpan(text: ' · ${zone.floor} · ${zone.detectorId}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DetectionPanel(
                      zoneName: zone.name,
                      subtitle:
                          '${zone.floor} · ${zone.detectorId} · type: ${event.type.label.toLowerCase()}',
                      confidence: event.confidence,
                    ),
                    const SizedBox(height: 12),
                    const _TrustBadge('Confirmed by 2 AI checks · object + scene'),
                    const SizedBox(height: 12),
                    _AiReportCard(
                      label: 'What the scene AI reports',
                      text: event.description,
                    ),
                    const SizedBox(height: 14),
                    const LocatorCard(
                      mode: FloorPlanMode.incidentRoute,
                      legend: [
                        LegendItem(AppColors.you, 'You'),
                        LegendItem(AppColors.danger, 'Fire — avoid'),
                        LegendItem(AppColors.safe, 'Fire exit'),
                        LegendItem(AppColors.planBlocked, 'Blocked exit'),
                        LegendItem(AppColors.planDoor, 'Door'),
                        LegendItem(AppColors.planWalkway, 'Walkway'),
                        LegendItem(AppColors.safe, 'Safe route'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MetaLine(
                      items: [
                        MetaItem('Detected', elapsedAgo(elapsed), isRed: true),
                        MetaItem('Confidence', '${event.confidencePct}%'),
                        MetaItem('Type', event.type.label),
                      ],
                    ),
                  ],
                ),
              ),
              _CtaBar(
                onSafe: () {
                  // Personal muster check-in (best-effort), then show the
                  // "you're marked safe" screen.
                  RepositoryScope.of(context).ackSafe();
                  context.pushReplacement('/resolved');
                },
                onCall: _callEmergency,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Live · confirmed emergency" pill with a softly pulsing halo.
class _IncidentFlag extends StatefulWidget {
  const _IncidentFlag();

  @override
  State<_IncidentFlag> createState() => _IncidentFlagState();
}

class _IncidentFlagState extends State<_IncidentFlag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.isAnimating ? _c.value : 0.0;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.stadium,
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.5 * (1 - t)),
                  spreadRadius: 10 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.danger,
            borderRadius: AppRadii.stadium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'LIVE · CONFIRMED EMERGENCY',
                style: AppText.pjs(12, 800, color: Colors.white, letterSpacing: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.trustBg,
          borderRadius: AppRadii.stadium,
          border: Border.all(color: AppColors.trustLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 15, color: AppColors.trustInk),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, style: AppText.trust.copyWith(color: AppColors.trustInk)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiReportCard extends StatelessWidget {
  const _AiReportCard({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    // A rounded card can't carry a non-uniform Border, so the 4px danger accent
    // is a clipped strip inside a uniformly-bordered card.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: AppColors.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.danger),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 13, color: AppColors.ink3),
                        const SizedBox(width: 6),
                        Text(label.toUpperCase(), style: AppText.quietLabel),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(text,
                        style: AppText.inter(15, 400,
                            color: AppColors.ink, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({required this.onSafe, required this.onCall});

  final VoidCallback onSafe;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            label: "I'm out — I'm safe",
            variant: PillVariant.safe,
            onPressed: onSafe,
          ),
          const SizedBox(height: 10),
          PillButton(
            label: 'Call emergency services',
            variant: PillVariant.danger,
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}
