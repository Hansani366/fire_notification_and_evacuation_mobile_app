import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/content_shell.dart';
import '../../data/mock/fire_repository.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import 'widgets/event_card.dart';

/// Flow B: the incident history log. Only events with recorded scene notes open
/// a detail (matching the prototype).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final events = repo.history;

    return ContentShell(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        children: [
          GreetingAppBar(
            title: 'History',
            subtitle:
                '${repo.siteName} · past 30 days · ${events.length} events',
          ),
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: EventCard(
                event: event,
                onTap: event.hasDetail
                    ? () => context.push('/history-detail/${event.id}')
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
