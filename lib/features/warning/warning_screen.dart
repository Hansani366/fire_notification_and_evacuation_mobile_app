import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/takeover_frame.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/meta_line.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/util/format.dart';

/// Tier 1a: gas above normal, nothing visible on camera.
///
/// **This screen is deliberately calm**, and three things are deliberately
/// absent from it:
///
/// - *No alarm styling.* Gas sensors react to cooking, aerosols, solvents and
///   vehicle exhaust. A warning that looked like an evacuation would, after two
///   or three frying pans, teach people to ignore the screen that means leave.
/// - *No evacuation route.* Nothing is burning. There is nothing to route away
///   from, and drawing one would assert a hazard the system has not found.
/// - *No muster roll.* A warning still carries one, and it would read "0 of 3
///   out" — which looks like a disaster while nothing at all has happened.
///
/// What it does show is the reading that triggered it, so the person can go and
/// check the actual cause.
class WarningScreen extends StatelessWidget {
  const WarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incident = RepositoryScope.of(context).activeIncident;
    final zone = incident.zone;
    final elapsed = DateTime.now().difference(incident.event.detectedAt);

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
                    const SizedBox(height: 10),
                    const _WarningFlag(),
                    const SizedBox(height: 14),
                    Text('⚠️ Gas levels rising', style: AppText.incidentTitle),
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
                    const SizedBox(height: 18),
                    _ReadingCard(
                      description: incident.event.description.isEmpty
                          ? 'Sensor readings are above normal. No fire seen on camera.'
                          : incident.event.description,
                      sensors: incident.sensorSummary,
                    ),
                    const SizedBox(height: 16),
                    const _NotAnAlarmNote(),
                    const SizedBox(height: 16),
                    MetaLine(
                      items: [
                        MetaItem('Noticed', elapsedAgo(elapsed)),
                        MetaItem('Camera', 'Nothing visible'),
                        MetaItem('Status', 'Zone clear'),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: PillButton(
                  label: 'Open site status',
                  variant: PillVariant.primary,
                  onPressed: () => context.go('/dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The amber counterpart of the incident screen's red pill. No pulsing halo —
/// motion reads as urgency, and this is not urgent.
class _WarningFlag extends StatelessWidget {
  const _WarningFlag();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          color: AppColors.warn,
          borderRadius: AppRadii.stadium,
        ),
        child: Text(
          'ADVISORY · NOT AN ALARM',
          style: AppText.pjs(12, 800, color: Colors.white, letterSpacing: 0.72),
        ),
      ),
    );
  }
}

/// The written warning, with the readings that produced it underneath.
class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.description, required this.sensors});

  final String description;
  final String sensors;

  @override
  Widget build(BuildContext context) {
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
            Container(width: 4, color: AppColors.warn),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sensors, size: 13, color: AppColors.ink3),
                        const SizedBox(width: 6),
                        Text('WHAT THE SENSORS REPORT', style: AppText.quietLabel),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(description,
                        style: AppText.inter(15, 400,
                            color: AppColors.ink, height: 1.5)),
                    if (sensors.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(sensors,
                          style: AppText.inter(12, 500, color: AppColors.ink3)),
                    ],
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

/// Says plainly what this is not. Without it the screen is just a yellow version
/// of the fire screen, and the distinction is the entire point of the tier.
class _NotAnAlarmNote extends StatelessWidget {
  const _NotAnAlarmNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.ink2),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'No evacuation is needed. Check for a leak, cooking or fumes in '
              'the area. Gas sensors also react to sprays, solvents and exhaust.',
              style: AppText.inter(13, 400, color: AppColors.ink2, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
