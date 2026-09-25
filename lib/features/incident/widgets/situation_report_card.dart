import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';

/// The situation report: what is burning, where, how big, the smoke, and who is
/// in the room — with each line carrying its own standing.
///
/// EVERY CLAIM HERE HAS ALREADY BEEN CHECKED. Statements the detector or sensor
/// evidence contradicted were removed before this ever reached the phone, which
/// is what RO3.1 means by validating before release rather than auditing
/// afterwards.
///
/// The one thing this widget must not do is flatten the difference between a
/// claim that was confirmed and one that nothing could check. Smoke colour is
/// genuinely useful and no sensor observes it; showing it as settled fact would
/// put an unverifiable statement in front of somebody deciding whether to go in.
/// So unsupported claims are shown — and marked.
class SituationReportCard extends StatelessWidget {
  const SituationReportCard({super.key, required this.report});

  final SituationReport report;

  @override
  Widget build(BuildContext context) {
    final claims = report.shown;
    if (claims.isEmpty && report.narrative.isEmpty) {
      return const SizedBox.shrink();
    }

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
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined,
                            size: 13, color: AppColors.ink3),
                        const SizedBox(width: 6),
                        Text('SITUATION REPORT', style: AppText.quietLabel),
                      ],
                    ),
                    const SizedBox(height: 9),
                    for (final c in claims) ...[
                      _ClaimLine(claim: c),
                      const SizedBox(height: 7),
                    ],
                    if (report.narrative.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        report.narrative,
                        style: AppText.inter(14, 400,
                            color: AppColors.ink2, height: 1.45),
                      ),
                    ],
                    if (report.hasUnverified || report.withheldCount > 0) ...[
                      const SizedBox(height: 11),
                      _Footnote(report: report),
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

class _ClaimLine extends StatelessWidget {
  const _ClaimLine({required this.claim});

  final ReportClaim claim;

  @override
  Widget build(BuildContext context) {
    final unverified = claim.grounding.needsMarking;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            unverified ? Icons.help_outline : Icons.check_circle_outline,
            size: 14,
            color: unverified ? AppColors.ink3 : AppColors.safe,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            runSpacing: 3,
            children: [
              Text(
                claim.text,
                style: AppText.inter(14.5, unverified ? 400 : 600,
                    color: unverified ? AppColors.ink2 : AppColors.ink),
              ),
              if (unverified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neutralBg,
                    borderRadius: AppRadii.stadium,
                  ),
                  child: Text('unverified',
                      style: AppText.inter(10.5, 600, color: AppColors.ink3)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Says what the marks mean, and admits when something was removed.
///
/// The withheld count is surfaced rather than hidden: a responder who is told
/// "one statement was withheld because the evidence contradicted it" is better
/// placed than one shown a seamless report with a hole in it.
class _Footnote extends StatelessWidget {
  const _Footnote({required this.report});

  final SituationReport report;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (report.hasUnverified)
        'Marked lines could not be checked against the sensors or the camera.',
      if (report.withheldCount > 0)
        report.withheldCount == 1
            ? '1 statement was withheld: the evidence contradicted it.'
            : '${report.withheldCount} statements were withheld: the evidence '
                'contradicted them.',
    ];
    return Text(
      parts.join(' '),
      style: AppText.inter(12, 400, color: AppColors.ink3, height: 1.4),
    );
  }
}
