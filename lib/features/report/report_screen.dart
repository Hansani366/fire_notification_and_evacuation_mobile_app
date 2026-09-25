import 'package:flutter/material.dart';

import '../../core/layout/content_shell.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/greeting_app_bar.dart';
import '../../shared/widgets/section_label.dart';

/// The record of one incident, read after it is over.
///
/// A responder wants to know what is burning. An investigation wants to know
/// **when the system knew it**, and those are different questions — which is why
/// this screen exists at all and why it is allowed to be long and dense where
/// the incident screen must be short.
///
/// The figure the whole escalation design turns on is `warningToFireS`: how much
/// notice the sensors gave before anything was visible on camera. It is measured
/// on every escalated incident and it disappears the moment the incident closes
/// unless something reads it back.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    // Fetched into the repository snapshot rather than awaited in `build`, so
    // this screen reads synchronously like every other one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RepositoryScope.of(context).loadReport(widget.incidentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = RepositoryScope.of(context).reportFor(widget.incidentId);

    return Scaffold(
      body: ContentShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            BackLabelButton(label: 'History', onTap: () => Navigator.of(context).pop()),
            const SizedBox(height: 4),
            if (report == null)
              const _Pending()
            else ...[
              GreetingAppBar(
                title: report.zoneName.isEmpty ? 'Incident report' : report.zoneName,
                subtitle: _headline(report),
              ),
              const SizedBox(height: 14),
              _Durations(report: report),
              if (report.timeline.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionLabel(label: 'Timeline'),
                const SizedBox(height: 8),
                _Timeline(events: report.timeline),
              ],
              if (report.guidance.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionLabel(label: 'Response'),
                const SizedBox(height: 8),
                _Block(
                  title: report.fuelLabel ?? 'Fuel not identified',
                  body: report.guidance,
                  accent: AppColors.warn,
                ),
              ],
              const SizedBox(height: 18),
              const SectionLabel(label: 'Evacuation'),
              const SizedBox(height: 8),
              _Evacuation(report: report),
              if (report.caveats.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionLabel(label: 'Limits'),
                const SizedBox(height: 8),
                _Caveats(items: report.caveats),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _headline(IncidentReport r) {
    if (r.escalatedFromWarning) return 'Escalated from a gas warning';
    return switch (r.severity) {
      IncidentSeverity.warning => 'Gas warning',
      IncidentSeverity.gasDanger => 'Gas alarm · nothing visible on camera',
      IncidentSeverity.fire => 'Fire confirmed on camera',
    };
  }
}

class _Pending extends StatelessWidget {
  const _Pending();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 14),
            Text('Loading the record…',
                style: AppText.inter(14, 400, color: AppColors.ink2)),
          ],
        ),
      );
}

/// The gaps between the stamps — the part an investigation reads first.
class _Durations extends StatelessWidget {
  const _Durations({required this.report});

  final IncidentReport report;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      if (report.warningToFireS case final s?)
        ('Warning → fire', '${s}s', 'notice the sensors gave first'),
      if (report.fireToClassifiedS case final s?)
        ('Fire → fuel known', '${s}s', 'sensors catching up with the camera'),
      if (report.totalS case final s?) ('Total', '${s}s', 'open to closed'),
      if (report.deliveryP50Ms case final ms?)
        ('Alert delivered', '${ms.round()} ms', 'median, round trip halved'),
      if (report.routeLatencyMs case final ms?)
        ('Route ready', '${(ms / 1000).toStringAsFixed(1)}s', 'after detection'),
    ];
    if (rows.isEmpty) {
      return Text('No timings recorded for this incident.',
          style: AppText.inter(14, 400, color: AppColors.ink2));
    }
    return Column(
      children: [
        for (final (label, value, note) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: Text(label,
                      style: AppText.inter(14, 600, color: AppColors.ink)),
                ),
                SizedBox(
                  width: 74,
                  child: Text(value,
                      style: AppText.pjs(15, 800, color: AppColors.ink)),
                ),
                Expanded(
                  child: Text(note,
                      style: AppText.inter(12.5, 400, color: AppColors.ink3)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<ReportEvent> events;

  String _clock(DateTime? at) => at == null
      ? '--:--:--'
      : '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}:'
          '${at.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.ink3, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.what,
                                style: AppText.inter(14.5, 600,
                                    color: AppColors.ink)),
                          ),
                          Text(_clock(e.at),
                              style: AppText.inter(12.5, 500,
                                  color: AppColors.ink3)),
                        ],
                      ),
                      if (e.detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(e.detail,
                            style: AppText.inter(13, 400,
                                color: AppColors.ink2, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Route taken, and the two occupancy counts **side by side**.
///
/// They are not reconciled into one figure here or anywhere else. The gap
/// between what the camera saw and who said they were out is the finding, not a
/// discrepancy to be tidied away.
class _Evacuation extends StatelessWidget {
  const _Evacuation({required this.report});

  final IncidentReport report;

  @override
  Widget build(BuildContext context) {
    final c = report.checkout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.routeExitName case final name?)
          _Line('Route',
              '$name${report.routeLengthM == null ? '' : ' · ${report.routeLengthM!.toStringAsFixed(1)} m'}'),
        _Line('Checked out', '${c.checkedOut}'),
        _Line('Peak head-count',
            c.peakOccupancy == null ? 'not recorded' : '${c.peakOccupancy}'),
        if (c.isKnown) _Line('Difference', '${c.unaccounted}'),
        const SizedBox(height: 6),
        Text(
          c.isKnown
              ? 'Two separate measurements of the same evacuation. Neither is '
                  'corrected against the other.'
              : 'The camera had no head-count for this incident, so the two '
                  'counts cannot be compared.',
          style: AppText.inter(12.5, 400, color: AppColors.ink3, height: 1.4),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: AppText.inter(14, 400, color: AppColors.ink2)),
            ),
            Expanded(
              child: Text(value,
                  style: AppText.inter(14, 600, color: AppColors.ink)),
            ),
          ],
        ),
      );
}

class _Caveats extends StatelessWidget {
  const _Caveats({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        decoration: BoxDecoration(
          color: AppColors.neutralBg,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.info_outline,
                          size: 14, color: AppColors.ink3),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c,
                          style: AppText.inter(12.5, 400,
                              color: AppColors.ink2, height: 1.45)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.body, required this.accent});

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
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
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppText.inter(14.5, 700, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text(body,
                          style: AppText.inter(14, 400,
                              color: AppColors.ink2, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
