import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/content_shell.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/meta_line.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import 'widgets/scene_timeline.dart';

/// Detail for a resolved history event: headline stats + AI scene-note timeline.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final event = RepositoryScope.of(context).historyById(eventId);

    return Scaffold(
      body: ContentShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            BackLabelButton(label: 'History', onTap: () => context.pop()),
            if (event == null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Event not found', style: AppText.sectionTitle),
                ),
              )
            else ...[
              GreetingAppBar(
                title: '🔥 ${event.zoneName} fire',
                subtitle: '${event.whenLabel} · resolved',
                trailing: StatusChip(
                  label: event.resolution.label,
                  tone: ChipTone.fire,
                  size: ChipSize.small,
                ),
              ),
              const SizedBox(height: 8),
              MetaLine(
                items: [
                  MetaItem('Duration', '${event.durationMin} min'),
                  MetaItem('Peak conf.', '${event.peakConfidencePct}%'),
                  MetaItem('Resolved', _resolvedBy(event.resolution), small: true),
                ],
              ),
              const SizedBox(height: 16),
              const SectionLabel(label: 'AI scene notes during the event'),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 4),
                child: SceneTimeline(notes: event.sceneNotes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resolvedBy(Resolution r) => switch (r) {
        Resolution.userConfirmed => 'By user',
        Resolution.autoCleared => 'Auto',
        Resolution.falseAlarm => 'False',
      };
}
