import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';

/// What is burning, and what to fight it with.
///
/// Three rules this widget exists to enforce:
///
/// 1. **The guidance sentence is rendered verbatim.** It is never rebuilt from
///    the fuel enum on this side. The dashboard, the incident record and the
///    phone all read one table in the backend precisely so they cannot end up
///    giving three different answers about the same fire.
/// 2. **It says "Likely", and it says the verdict is unvalidated.** Both models
///    behind it were trained on CFAST simulation and have never seen a recorded
///    fire. Presenting that as a finding would be the one dishonesty that could
///    actually get someone hurt — applying the wrong agent makes a fire worse.
/// 3. **A pending verdict is shown, not hidden.** `source == 'unavailable'`
///    means the sensors were still reading clean air. A blank space there looks
///    like a bug, and the responder deserves to know an answer is coming.
class GuidanceCard extends StatelessWidget {
  const GuidanceCard({super.key, required this.classification});

  final FireClassification classification;

  @override
  Widget build(BuildContext context) {
    final pending = classification.isPending;
    final accent = pending ? AppColors.ink3 : AppColors.warn;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: pending ? AppColors.card : AppColors.warnBg,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: pending ? AppColors.line : AppColors.warn.withValues(alpha: 0.35)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(pending ? Icons.hourglass_empty : Icons.fire_extinguisher,
                            size: 13, color: AppColors.ink3),
                        const SizedBox(width: 6),
                        Text('FIRE FIGHTING GUIDANCE', style: AppText.quietLabel),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (pending)
                      Text(
                        'Identifying fuel…',
                        style: AppText.inter(15, 400, color: AppColors.ink2, height: 1.5),
                      )
                    else ...[
                      Text(
                        classification.guidance,
                        style: AppText.inter(15, 600, color: AppColors.ink, height: 1.45),
                      ),
                      const SizedBox(height: 9),
                      _LikelyLine(classification: classification),
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

/// "Likely: liquid fuel fire · Class B · unvalidated".
///
/// The hedge and the caveat sit on the same line as the verdict on purpose — a
/// reader under time pressure should not be able to take the fuel class without
/// also taking the reason to doubt it.
class _LikelyLine extends StatelessWidget {
  const _LikelyLine({required this.classification});

  final FireClassification classification;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      'Likely: ${classification.label.toLowerCase()}',
      if (classification.fireClass.isNotEmpty) 'Class ${classification.fireClass}',
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 4,
      children: [
        Text(parts.join(' · '), style: AppText.inter(13, 500, color: AppColors.warnInk)),
        if (classification.isUnvalidated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: AppRadii.stadium,
            ),
            child: Text('unvalidated',
                style: AppText.inter(11, 600, color: AppColors.ink2)),
          ),
      ],
    );
  }
}
