import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/layout/content_shell.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../../data/mock/fire_repository.dart';
import '../../shared/widgets/flame_icon.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/health_row.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/status_hero.dart';
import '../../shared/widgets/zone_card.dart';

/// Flow B home: site status (live "All clear" or a fire banner), system health,
/// and the zone list. Rebuilds automatically as the live repository updates.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final zones = repo.zones;
    final incident = repo.activeIncident;
    // TWO CONDITIONS, NOT ONE. During an open gas warning the backend returns
    // `allClear: true` *and* an active incident, deliberately: nothing is
    // burning, so no zone turns red. Reading only `allClear` printed "All clear"
    // across the top of the screen while a warning was live underneath it.
    final allClear = repo.allClear && !repo.hasActiveIncident;

    return ContentShell(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        children: [
          // Long-press the header to point the app at a different server (demo).
          GestureDetector(
            onLongPress: () => _showServerDialog(context, repo),
            child: GreetingAppBar(
              title: 'Site status',
              subtitle: '${repo.siteName} · all zones · updated just now',
              trailing: RoundIconButton(
                icon: Icons.notifications_active_outlined,
                tooltip: 'Simulate alarm',
                onTap: () => context.push('/lock'),
              ),
            ),
          ),
          if (allClear)
            StatusHero(
              title: 'All clear',
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Last full scan '),
                    TextSpan(
                      text: 'just now',
                      style: AppText.inter(14, 600, color: AppColors.ink),
                    ),
                    TextSpan(text: ' · ${repo.detectorCount} detectors watching'),
                  ],
                ),
              ),
            )
          else
            _AlertHero(
              incident: incident,
              onTap: () => context.push(
                  incident.severity == IncidentSeverity.warning ? '/warning' : '/incident'),
            ),
          const SizedBox(height: 16),
          HealthRow(stats: repo.health),
          const SizedBox(height: 6),
          SectionLabel(label: 'Zones', trailing: '${zones.length}'),
          for (final zone in zones)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: ZoneCard(
                zone: zone,
                onTap: () => context.push('/zone/${zone.id}'),
              ),
            ),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context, FireRepository repo) {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.10:8090',
            helperText: 'The alert-service address on your LAN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await AppConfig.setBaseUrl(controller.text);
              await repo.refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Red "fire detected" hero shown on the dashboard while an incident is active.
class _AlertHero extends StatelessWidget {
  const _AlertHero({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  /// A gas warning is not an emergency and must not be painted like one. Amber
  /// for "we are watching something", red only for an alarm that means leave.
  Color get _tone =>
      incident.severity == IncidentSeverity.warning ? AppColors.warn : AppColors.danger;

  Color get _toneBg =>
      incident.severity == IncidentSeverity.warning ? AppColors.warnBg : AppColors.dangerBg;

  String get _headline => switch (incident.severity) {
        IncidentSeverity.warning => '⚠️ Gas levels rising',
        IncidentSeverity.gasDanger => '⚠️ Dangerous gas',
        IncidentSeverity.fire => '🔥 Fire detected',
      };

  /// No percentage here either: a sensor-only alarm carries 0.0 by design, and
  /// "Confirmed 0%" on the dashboard is the same falsehood as on the incident
  /// screen, just smaller.
  String get _subtitle => switch (incident.severity) {
        IncidentSeverity.warning => 'No fire seen on camera · tap for details',
        IncidentSeverity.gasDanger => 'Detected by sensors · tap for your safe route',
        IncidentSeverity.fire => incident.hasMeaningfulConfidence
            ? 'Confirmed ${incident.event.confidencePct}% · tap for your safe route'
            : 'Confirmed on camera · tap for your safe route',
      };

  @override
  Widget build(BuildContext context) {
    final zone = incident.zone;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.large,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: _toneBg,
            borderRadius: AppRadii.large,
            border: Border.all(color: _tone.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _tone,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _tone.withValues(alpha: 0.32),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FlameIcon(size: 26, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_headline,
                          style: AppText.pjs(20, 800, color: _tone)),
                      const SizedBox(height: 3),
                      Text('${zone.name} · ${zone.floor}',
                          style: AppText.inter(14, 600, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(_subtitle,
                          style: AppText.inter(13, 400, color: AppColors.ink2)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: _tone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
