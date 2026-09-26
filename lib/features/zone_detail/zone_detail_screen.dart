import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/content_shell.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../data/models/models.dart';
import '../../shared/floor_plan/floor_plan_data.dart';
import '../../shared/floor_plan/locator_card.dart';
import '../../shared/util/format.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/status_hero.dart';

/// Detail for a single (clear) zone: status hero + this-zone floor plan.
class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final zone = repo.zoneById(zoneId);

    return Scaffold(
      body: ContentShell(
        child: zone == null
            ? _NotFound(onBack: () => context.pop())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                children: [
                  BackLabelButton(
                    label: 'Site status',
                    onTap: () => context.pop(),
                  ),
                  GreetingAppBar(
                    title: zone.name,
                    subtitle: '${zone.floor} · ${zone.detectorId}',
                    // Was hard-coded to "All clear" regardless of state, so a
                    // burning zone's own detail screen said it was fine.
                    trailing: StatusChip(
                      label: zone.status == ZoneStatus.clear
                          ? 'All clear'
                          : zone.status.label,
                      tone: switch (zone.status) {
                        ZoneStatus.clear => ChipTone.clear,
                        ZoneStatus.smoke => ChipTone.smoke,
                        ZoneStatus.fire => ChipTone.fire,
                      },
                    ),
                  ),
                  StatusHero(
                    iconSize: 48,
                    iconRadius: 15,
                    titleSize: 24,
                    title: zone.status == ZoneStatus.clear
                        ? 'No fire or smoke'
                        : zone.status.label,
                    subtitle: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: zone.status == ZoneStatus.clear
                                  ? 'Both AI checks agree · last scan '
                                  : 'Under review · last scan '),
                          TextSpan(
                            text: scannedAgo(zone.lastScanAt)
                                .replaceFirst('Scanned ', ''),
                            style: AppText.inter(14, 600, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LocatorCard(
                    plan: FloorPlan.forSiteKey(repo.siteKey) ?? FloorPlan.home,
                    mode: FloorPlanMode.zoneSafe,
                    // Was pinned to the Fabric Store, so every zone's detail
                    // screen highlighted a room the reader was not looking at.
                    focusRoomId: zoneId,
                    header: 'This zone · ${zone.floor}',
                    legend: const [
                      LegendItem(AppColors.safe, 'This zone · safe'),
                      LegendItem(AppColors.safe, 'Fire exit'),
                      LegendItem(AppColors.planDoor, 'Door'),
                      LegendItem(AppColors.planWalkway, 'Walkway'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackLabelButton(label: 'Back', onTap: onBack),
          const SizedBox(height: 40),
          Center(
            child: Text('Zone not found', style: AppText.sectionTitle),
          ),
        ],
      ),
    );
  }
}
