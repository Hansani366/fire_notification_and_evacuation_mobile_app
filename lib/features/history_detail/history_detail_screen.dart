import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/content_shell.dart';
import '../../core/theme/app_tokens.dart';
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
              const SizedBox(height: 16),
              _ReportLink(historyId: event.id),
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

/// Opens the incident record — the timeline, the measured notice the sensors
/// gave, and the two occupancy counts. Built and served since before this
/// screen existed, and until now nothing linked to it.
class _ReportLink extends StatelessWidget {
  const _ReportLink({required this.historyId});

  final String historyId;

  /// History ids carry an `h_` prefix over the incident id (the backend's
  /// `history_json`); the report endpoint wants the bare one.
  String get _incidentId =>
      historyId.startsWith('h_') ? historyId.substring(2) : historyId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: () => context.push('/report/$_incidentId'),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 18, color: AppColors.ink2),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full incident record',
                          style: AppText.inter(14.5, 600, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Timeline, response and evacuation counts',
                          style: AppText.inter(12.5, 400, color: AppColors.ink3)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
