import 'package:firewatch/app.dart';
import 'package:firewatch/core/config/app_config.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:firewatch/data/mock/mock_data.dart';
import 'package:firewatch/data/models/models.dart';
import 'package:firewatch/shared/floor_plan/floor_plan_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The phone's own escape-route layout switch.
///
/// It is deliberately independent of the dashboard's detection setting: neither
/// reads the other. What this file pins is that independence, and the one case
/// it creates — a route generated for a building the phone is not showing.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the setting', () {
    test('defaults to industrial', () {
      expect(FloorPlan.bySiteKey(AppConfig.exitLayout).siteKey, isNotEmpty);
      expect(AppConfig.exitLayout, anyOf('unit7', 'home'));
    });

    test('switching picks the other plan', () async {
      await AppConfig.setExitLayout('home');
      expect(AppConfig.exitLayout, 'home');
      expect(FloorPlan.bySiteKey(AppConfig.exitLayout), FloorPlan.home);

      await AppConfig.setExitLayout('unit7');
      expect(FloorPlan.bySiteKey(AppConfig.exitLayout), FloorPlan.unit7);
    });

    test('an unknown value falls back rather than throwing', () async {
      await AppConfig.setExitLayout('nonsense');
      expect(AppConfig.exitLayout, 'unit7');
    });

    test('it survives a restart', () async {
      await AppConfig.setExitLayout('home');
      SharedPreferences.setMockInitialValues({'exit_layout': 'home'});
      await AppConfig.load();
      expect(AppConfig.exitLayout, 'home');
    });

    test('it is the phone\'s own setting, not the backend\'s', () async {
      // The repository reports both. They are read from different places and
      // must be free to disagree.
      await AppConfig.setExitLayout('home');
      final repo = MockFireRepository();
      expect(repo.exitLayout, 'home');
      expect(repo.siteKey, 'unit7');      // the backend handshake default
    });
  });

  group('a route for a building the phone is not showing', () {
    Incident withRouteFor(String siteKey) {
      final now = DateTime.now();
      final zone = MockData.zones(now).first;
      return Incident(
        id: 'inc_test',
        zone: zone,
        event: DetectionEvent(
          zoneId: zone.id,
          type: DetectionType.fire,
          detected: true,
          confidence: 0.9,
          description: 'Flames.',
          detectedAt: now.subtract(const Duration(seconds: 10)),
        ),
        muster: const MusterRoll(present: 1, total: 3),
        route: EvacRoute(
          status: RouteStatus.exit,
          siteKey: siteKey,
          planRevision: '2026-09-25.1',
          fireZoneId: zone.id,
          from: const Offset(163, 55),
          hazardAt: const Offset(42, 66),
          hazardRadiusPx: 60,
          polyline: const [Offset(163, 55), Offset(163, 171), Offset(333, 171)],
          blockedExitIds: const ['exit-north'],
          instruction: 'Leave through the east fire exit.',
          exitId: 'exit-east',
          exitName: 'EAST FIRE EXIT',
        ),
      );
    }

    /// Scroll until [finder] is built. The incident screen is a ListView, so
    /// the locator card and everything near it does not exist in the tree until
    /// it is scrolled into range.
    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
        duration: const Duration(milliseconds: 20),
      );
    }

    Future<void> openIncident(WidgetTester tester, Incident incident) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final router = buildRouter();
      await tester.pumpWidget(FireWatchApp(
        repository: MockFireRepository(incident: incident, live: true),
        router: router,
      ));
      await tester.pumpAndSettle();
      router.go('/incident');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('is refused, and says so', (tester) async {
      // Phone showing the home plan; route computed for the factory.
      await AppConfig.setExitLayout('home');
      await openIncident(tester, withRouteFor('unit7'));

      await scrollTo(tester, find.textContaining('No route shown'));
      expect(find.textContaining('No route shown'), findsOneWidget);
      // A correct path through the wrong walls looks exactly as authoritative
      // as a right one, so the instruction must not appear either.
      expect(find.text('Leave through the east fire exit.'), findsNothing);
    });

    testWidgets('is drawn when the layouts agree', (tester) async {
      await AppConfig.setExitLayout('unit7');
      await openIncident(tester, withRouteFor('unit7'));

      await scrollTo(tester, find.text('Leave through the east fire exit.'));
      expect(find.textContaining('No route shown'), findsNothing);
      expect(find.text('Leave through the east fire exit.'), findsOneWidget);
    });

    testWidgets('a route with no site key is trusted', (tester) async {
      // Older incidents predate the field; refusing them would lose the route
      // for every record generated before the setting existed.
      await AppConfig.setExitLayout('home');
      await openIncident(tester, withRouteFor(''));

      await scrollTo(tester, find.text('Leave through the east fire exit.'));
      expect(find.textContaining('No route shown'), findsNothing);
      expect(find.text('Leave through the east fire exit.'), findsOneWidget);
    });
  });
}
