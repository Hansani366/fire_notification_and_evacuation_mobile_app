import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/takeover_frame.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../data/models/models.dart';
import '../../shared/floor_plan/floor_plan_data.dart';
import '../../shared/floor_plan/locator_card.dart';
import '../../shared/util/format.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/meta_line.dart';
import '../../shared/widgets/pill_button.dart';
import 'widgets/detection_panel.dart';
import 'widgets/guidance_card.dart';

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
    final isFire = incident.severity == IncidentSeverity.fire;
    final occupants = incident.occupancy.current;

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
                    _IncidentFlag(severity: incident.severity),
                    const SizedBox(height: 14),
                    Text(
                      // Tier 1b is an alarm with nothing visible on camera.
                      // Announcing a flame nobody saw is the one thing this
                      // screen must not do.
                      isFire ? '🔥 Fire detected' : '⚠️ Dangerous gas',
                      style: AppText.incidentTitle,
                    ),
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
                      subtitle: isFire
                          ? '${zone.floor} · ${zone.detectorId} · type: ${event.type.label.toLowerCase()}'
                          : '${zone.floor} · ${zone.detectorId} · nothing visible on camera',
                      // Null suppresses the meter entirely — see DetectionPanel.
                      confidence:
                          incident.hasMeaningfulConfidence ? event.confidence : null,
                      evidenceNote: 'Detected by sensors',
                      isFlame: isFire,
                    ),
                    const SizedBox(height: 12),
                    _TrustBadge(incident: incident),
                    if (occupants != null) ...[
                      const SizedBox(height: 12),
                      _OccupancyLine(count: occupants),
                    ],
                    const SizedBox(height: 12),
                    _AiReportCard(
                      label: isFire
                          ? 'What the scene AI reports'
                          : 'What the sensors report',
                      text: event.description,
                    ),
                    if (incident.classification case final c?) ...[
                      const SizedBox(height: 12),
                      GuidanceCard(classification: c),
                    ],
                    const SizedBox(height: 14),
                    LocatorCard(
                      plan: FloorPlan.bySiteKey(incident.route?.siteKey),
                      mode: FloorPlanMode.incidentRoute,
                      route: incident.route,
                      focusRoomId: incident.route?.fireZoneId ?? zone.id,
                      legend: const [
                        LegendItem(AppColors.you, 'You'),
                        LegendItem(AppColors.danger, 'Fire — avoid'),
                        LegendItem(AppColors.safe, 'Fire exit'),
                        LegendItem(AppColors.planBlocked, 'Blocked exit'),
                        LegendItem(AppColors.planDoor, 'Door'),
                        LegendItem(AppColors.planWalkway, 'Walkway'),
                        LegendItem(AppColors.safe, 'Safe route'),
                      ],
                    ),
                    if (incident.route case final r?
                        when r.instruction.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _RouteInstruction(route: r),
                    ],
                    const SizedBox(height: 16),
                    MetaLine(
                      items: [
                        MetaItem('Detected', elapsedAgo(elapsed), isRed: true),
                        // "Confidence 0%" beside a live carbon-monoxide alarm
                        // looks like a fault. Name the evidence instead.
                        if (incident.hasMeaningfulConfidence)
                          MetaItem('Confidence', '${event.confidencePct}%')
                        else
                          MetaItem('Evidence', 'Sensors'),
                        MetaItem('Type', isFire ? event.type.label : 'Gas'),
                      ],
                    ),
                  ],
                ),
              ),
              _CtaBar(
                isRefuge: incident.route?.isRefuge ?? false,
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

/// The live-status pill with a softly pulsing halo.
///
/// The wording tracks the tier: "confirmed emergency" is a claim about evidence,
/// and a gas alarm has no camera confirmation behind it.
class _IncidentFlag extends StatefulWidget {
  const _IncidentFlag({required this.severity});

  final IncidentSeverity severity;

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
                widget.severity == IncidentSeverity.fire
                    ? 'LIVE · CONFIRMED EMERGENCY'
                    : 'LIVE · GAS ALARM',
                style: AppText.pjs(12, 800, color: Colors.white, letterSpacing: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What actually backs this alarm — never more than that.
///
/// This badge used to read "Confirmed by 2 AI checks · object + scene" on every
/// incident, including the ones where the scene model was unreachable and the
/// alarm was released on detection evidence alone (Algorithm 2's unavailable
/// branch), and including gas alarms where there was no image to check at all.
/// Overstating the evidence is worst precisely where it is most tempting: on the
/// screen someone reads while deciding whether to believe it.
class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.incident});

  final Incident incident;

  ({String label, IconData icon, bool warn}) get _content {
    if (incident.severity != IncidentSeverity.fire) {
      return (
        label: 'Raised by sensor readings · no camera confirmation',
        icon: Icons.sensors,
        warn: true,
      );
    }
    return switch (incident.verification) {
      Verification.confirmed => (
          label: 'Confirmed by 2 AI checks · object + scene',
          icon: Icons.verified_user_outlined,
          warn: false,
        ),
      Verification.unavailable => (
          label: 'Scene check unavailable · camera and sensors only',
          icon: Icons.cloud_off_outlined,
          warn: true,
        ),
      _ => (
          label: 'Detection evidence only',
          icon: Icons.info_outline,
          warn: true,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _content;
    final fg = c.warn ? AppColors.warnInk : AppColors.trustInk;
    final bg = c.warn ? AppColors.warnBg : AppColors.trustBg;
    final line = c.warn ? AppColors.warn.withValues(alpha: 0.35) : AppColors.trustLine;
    return _BadgeShell(label: c.label, icon: c.icon, fg: fg, bg: bg, line: line);
  }
}

class _BadgeShell extends StatelessWidget {
  const _BadgeShell({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.line,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadii.stadium,
          border: Border.all(color: line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, style: AppText.trust.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "3 people still in the zone" — the most actionable fact on the screen.
///
/// Only rendered when the human detector actually has a number. A null count
/// means it had nothing to say, which is not the same as an empty room, and
/// printing "0 people" for it would be the one error this figure must not make.
class _OccupancyLine extends StatelessWidget {
  const _OccupancyLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final people = count == 1 ? '1 person' : '$count people';
    return Row(
      children: [
        const Icon(Icons.groups_outlined, size: 17, color: AppColors.dangerInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            count == 0 ? 'No one detected in the zone' : '$people still in the zone',
            style: AppText.inter(15, 600,
                color: count == 0 ? AppColors.ink2 : AppColors.dangerInk),
          ),
        ),
      ],
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

/// The one line telling the occupant what to do, in words.
///
/// The drawing shows the way; this says it. Under smoke, in the dark, or with a
/// phone held at arm's length, the sentence is the part that survives.
class _RouteInstruction extends StatelessWidget {
  const _RouteInstruction({required this.route});

  final EvacRoute route;

  @override
  Widget build(BuildContext context) {
    final refuge = route.isRefuge;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: refuge ? AppColors.warnBg : AppColors.safeBg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
            color: (refuge ? AppColors.warn : AppColors.safe)
                .withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(refuge ? Icons.shield_outlined : Icons.directions_walk,
              size: 18, color: refuge ? AppColors.warnInk : AppColors.safeInk),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              route.instruction,
              style: AppText.inter(15, 600,
                  color: refuge ? AppColors.warnInk : AppColors.safeInk,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.onSafe,
    required this.onCall,
    this.isRefuge = false,
  });

  final VoidCallback onSafe;
  final VoidCallback onCall;

  /// No exit was reachable. Offering "I'm out — I'm safe" to somebody who has
  /// just been told to shut a door and wait is worse than useless: it invites
  /// the one action the route generator refused to recommend.
  final bool isRefuge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRefuge) ...[
            PillButton(
              label: "I'm out — I'm safe",
              variant: PillVariant.safe,
              onPressed: onSafe,
            ),
            const SizedBox(height: 10),
          ],
          PillButton(
            label: isRefuge
                ? 'Call emergency services — tell them where you are'
                : 'Call emergency services',
            variant: PillVariant.danger,
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}
