import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/takeover_frame.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/fire_repository.dart';
import '../../shared/util/format.dart';
import 'widgets/critical_notification_card.dart';

/// Flow A entry: a lock screen with a critical FireWatch push. The big clock is
/// live; the notification opens the incident (takeover).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incident = RepositoryScope.of(context).activeIncident;
    const white85 = Color(0xD9FFFFFF);
    const white50 = Color(0x80FFFFFF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: TakeoverFrame(
          gradient: AppGradients.lock,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 6),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go('/dashboard'),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.close, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(lockDate(_now),
                  style: AppText.inter(15, 500, color: white85)),
              const SizedBox(height: 6),
              // Guard the 74px numeral against narrow screens / large text scale.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(clockTime(_now),
                    style: AppText.lockClock.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CriticalNotificationCard(
                  title:
                      '🔥 Fire detected — ${incident.zone.name}, ${incident.zone.floor}',
                  body:
                      'Two AI checks confirmed flames among the fabric rolls. Do '
                      'not enter the store. Leave by the east door and follow the '
                      'aisle to the East fire exit. Tap for your safe route.',
                  onTap: () => context.pushReplacement('/incident'),
                  onSeeRoute: () => context.pushReplacement('/incident'),
                  onSafe: () => context.pushReplacement('/resolved'),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Critical alert · bypasses silent & Do Not Disturb\n'
                  'Tap the alert to open FireWatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: white50,
                    fontSize: 12,
                    height: 1.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
