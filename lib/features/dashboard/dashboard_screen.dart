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
    final allClear = repo.allClear;

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
              incident: repo.activeIncident,
              onTap: () => context.push('/incident'),
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

  @override
  Widget build(BuildContext context) {
    final zone = incident.zone;
    final event = incident.event;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.large,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: AppRadii.large,
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.32),
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
                      Text('🔥 Fire detected',
                          style: AppText.pjs(20, 800, color: AppColors.danger)),
                      const SizedBox(height: 3),
                      Text('${zone.name} · ${zone.floor}',
                          style: AppText.inter(14, 600, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Confirmed ${event.confidencePct}% · tap for your safe route',
                          style: AppText.inter(13, 400, color: AppColors.ink2)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
