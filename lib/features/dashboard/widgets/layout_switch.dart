import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/fire_repository.dart';

/// Chooses which building's escape-route layout this phone draws.
///
/// INDEPENDENT OF THE DASHBOARD'S SWITCH, ON PURPOSE. The web dashboard has its
/// own setting for what counts as a fire; this one picks the floor plan. Neither
/// reads the other, so a phone can be pointed at a different layout without
/// touching the server, and a server restart cannot quietly change what a
/// responder is looking at.
///
/// Shown on the dashboard rather than hidden behind a long-press, because
/// somebody glancing at this screen should be able to see which building it
/// thinks it is in before an alarm makes that urgent.
class LayoutSwitch extends StatelessWidget {
  const LayoutSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final current = repo.exitLayout;

    return Row(
      children: [
        const Icon(Icons.map_outlined, size: 15, color: AppColors.ink3),
        const SizedBox(width: 7),
        // Expanded, not Spacer: the two chips have a fixed width and the label
        // is the only thing that can give. With a Spacer this row overflows on
        // a narrow phone, and an overflow stripe across the dashboard is not a
        // good look on the screen someone checks before an alarm.
        Expanded(
          child: Text('ROUTE LAYOUT',
              style: AppText.quietLabel, overflow: TextOverflow.ellipsis),
        ),
        for (final option in const [
          ('industrial', 'Industrial'),
          ('home', 'Home demo'),
        ])
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _Option(
              label: option.$2,
              selected: current == option.$1,
              onTap: () async {
                if (current == option.$1) return;
                await AppConfig.setExitLayout(option.$1);
                // Screens read the repository, so the repository announces it.
                repo.notifyLayoutChanged();
              },
            ),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.stadium,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.inkStrong : AppColors.neutralBg,
            borderRadius: AppRadii.stadium,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Text(
              label,
              style: AppText.inter(12, 600,
                  color: selected ? Colors.white : AppColors.ink2),
            ),
          ),
        ),
      ),
    );
  }
}
