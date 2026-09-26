import 'package:firewatch/app.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:firewatch/data/mock/mock_data.dart';
import 'package:firewatch/data/models/models.dart';
import 'package:firewatch/shared/floor_plan/floor_plan_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_surface.dart';

/// A route generated for a building this app does not draw.
///
/// The app draws one facility, the trial house. The backend can be pointed at
/// another site without the app knowing, and a polyline only means anything in
/// the coordinate space it was computed in. So a route whose site key is not
/// ours is REFUSED, with a line on screen saying why. A correct path through the
/// wrong walls looks exactly as authoritative as a right one, which makes
/// drawing it the worse failure.
///
/// There used to be a switch on the dashboard that chose between two layouts,
/// and this file used to pin that the switch and the backend were free to
/// disagree. The second layout is gone -- no trial could run in it -- but the
/// disagreement it created can still arrive from the backend, so the refusal
/// stays and so does its test.
void main() {
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
      useTallSurface(tester);
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
      // The app draws the house; this route was computed for another building.
      await openIncident(tester, withRouteFor('industrial'));

      await scrollTo(tester, find.textContaining('No route shown'));
      expect(find.textContaining('No route shown'), findsOneWidget);
      // A correct path through the wrong walls looks exactly as authoritative
      // as a right one, so the instruction must not appear either.
      expect(find.text('Leave through the east fire exit.'), findsNothing);
    });

    testWidgets('is drawn when the site keys agree', (tester) async {
      await openIncident(tester, withRouteFor('home'));

      await scrollTo(tester, find.text('Leave through the east fire exit.'));
      expect(find.textContaining('No route shown'), findsNothing);
      expect(find.text('Leave through the east fire exit.'), findsOneWidget);
      // The plan itself must be on screen, not just the instruction under it.
      expect(find.byType(FloorPlanView), findsOneWidget);
    });

    testWidgets('a route with no site key is trusted', (tester) async {
      // Older incidents predate the field; refusing them would lose the route
      // for every record generated before it existed.
      await openIncident(tester, withRouteFor(''));

      await scrollTo(tester, find.text('Leave through the east fire exit.'));
      expect(find.textContaining('No route shown'), findsNothing);
      expect(find.text('Leave through the east fire exit.'), findsOneWidget);
    });
  });
}
