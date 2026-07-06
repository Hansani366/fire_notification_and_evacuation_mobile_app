import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';

/// The vertical AI scene-notes timeline (`.timeline`), colour-coded per note.
class SceneTimeline extends StatelessWidget {
  const SceneTimeline({super.key, required this.notes});

  final List<SceneNote> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < notes.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Gutter(state: notes[i].state, isLast: i == notes.length - 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == notes.length - 1 ? 4 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notes[i].timeLabel,
                          style: AppText.inter(11, 600, color: AppColors.ink3),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notes[i].text,
                          style: AppText.inter(13.5, 400,
                              color: AppColors.ink, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter({required this.state, required this.isLast});

  final SceneState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (Color node, bool filled) = switch (state) {
      SceneState.fire => (AppColors.danger, true),
      SceneState.smoke => (AppColors.warn, true),
      SceneState.cleared => (AppColors.ink3, false),
    };

    return SizedBox(
      width: 13,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // connector line (hidden on the last item)
          Positioned(
            top: 6,
            bottom: 0,
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : AppColors.line,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? node : AppColors.card,
              border: Border.all(color: node, width: 2.5),
            ),
          ),
        ],
      ),
    );
  }
}
