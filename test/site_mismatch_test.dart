import 'package:firewatch/app.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:firewatch/data/mock/mock_data.dart';
import 'package:firewatch/data/models/models.dart';
import 'package:firewatch/shared/floor_plan/floor_plan_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_surface.dart';

/// Which floor plan a route is drawn on, and what happens when there is none.
///
/// The plan is chosen from the data: the route names the site it was generated
/// for, and `FloorPlan.forSiteKey` finds the drawing for it. A polyline only
/// means anything in the coordinate space it was computed in -- home is 25 px/m
/// and industrial is 10 px/m -- so a route is drawn on its OWN site's plan or
/// not at all. When this build has no plan for that site the route is withheld
/// and the screen says why, because a correct path through the wrong walls looks
/// exactly as authoritative as a right one.
///
/// There used to be a switch on the dashboard choosing between the two layouts,
/// and this file used to pin that the switch and the backend were free to
/// disagree. That was the bug, not the feature: nothing reconciled them. The
/// switch is gone and the data decides, so the cases below are about site keys
/// rather than about a setting.
void main() {
  group('choosing the plan for a route', () {
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

    testWidgets('a site with no plan in this build is refused, and says so',
        (tester) async {
      // Not 'industrial' -- this build has that drawing. A site key it has never
      // been given artwork for is the case that must refuse.
      await openIncident(tester, withRouteFor('warehouse-b'));

      await scrollTo(tester, find.textContaining('No route shown'));
      expect(find.textContaining('No route shown'), findsOneWidget);
      // A correct path through the wrong walls looks exactly as authoritative
      // as a right one, so the instruction must not appear either.
      expect(find.text('Leave through the east fire exit.'), findsNothing);
    });

    testWidgets('the trial facility is drawn', (tester) async {
      await openIncident(tester, withRouteFor('home'));

      await scrollTo(tester, find.text('Leave through the east fire exit.'));
      expect(find.textContaining('No route shown'), findsNothing);
      expect(find.text('Leave through the east fire exit.'), findsOneWidget);
      // The plan itself must be on screen, not just the instruction under it.
      expect(find.byType(FloorPlanView), findsOneWidget);
    });

    testWidgets('an industrial route is drawn on the industrial plan',
        (tester) async {
      // `SITE_KEY=industrial` on the backend stamps its routes that way. The app
      // holds that drawing, so the route is drawn rather than refused -- no
      // setting on the phone has to be changed first, which is what used to be
      // required and what used to be got wrong.
      await openIncident(tester, withRouteFor('industrial'));

      await scrollTo(tester, find.text('Leave through the east fire exit.'));
      expect(find.textContaining('No route shown'), findsNothing);
      expect(find.text('Leave through the east fire exit.'), findsOneWidget);
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
