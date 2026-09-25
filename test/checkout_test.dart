import 'package:firewatch/app.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:firewatch/data/mock/mock_data.dart';
import 'package:firewatch/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Check-out, head-count and the incident record.
///
/// The rule under all of this: the camera count and the check-out count are two
/// instruments measuring the same evacuation, and the gap between them is the
/// finding. Nothing here may quietly reconcile them.
void main() {
  group('CheckoutRoll', () {
    test('reads both counts and the gap from the wire', () {
      final c = CheckoutRoll.fromJson({
        'checkedOut': 2,
        'peakOccupancy': 5,
        'currentOccupancy': 3,
        'unaccounted': 3,
      });
      expect(c.checkedOut, 2);
      expect(c.peakOccupancy, 5);
      expect(c.unaccounted, 3);
      expect(c.isKnown, isTrue);
    });

    test('an unknown head-count stays unknown, never zero', () {
      // "We lost the camera" and "the building is empty" look identical on a
      // screen and mean opposite things.
      final c = CheckoutRoll.fromJson({'checkedOut': 2, 'peakOccupancy': null});
      expect(c.isKnown, isFalse);
      expect(c.unaccounted, isNull);
      expect(c.peakOccupancy, isNull);
    });

    test('an incident with no checkout block defaults to nobody out', () {
      final inc = Incident.fromJson({
        'id': 'inc_1',
        'zone': {'id': 'fabric-store', 'name': 'Fabric Store'},
        'event': {'type': 'fire', 'confidence': 0.9},
        'muster': {'present': 1, 'total': 2},
      });
      expect(inc.checkout.checkedOut, 0);
      expect(inc.checkout.isKnown, isFalse);
    });

    test('check-out is never derived from the head-count', () {
      // muster is the camera's estimate; checkout is who tapped. They are
      // populated from different fields and must be able to disagree.
      final inc = Incident.fromJson({
        'id': 'inc_1',
        'zone': {'id': 'fabric-store', 'name': 'Fabric Store'},
        'event': {'type': 'fire', 'confidence': 0.9},
        'muster': {'present': 4, 'total': 5},
        'checkout': {'checkedOut': 1, 'peakOccupancy': 5, 'unaccounted': 4},
      });
      expect(inc.muster.present, 4);
      expect(inc.checkout.checkedOut, 1);
    });
  });

  group('IncidentReport', () {
    final wire = <String, dynamic>{
      'id': 'warn_abc',
      'severity': 'fire',
      'escalatedFromWarning': true,
      'zone': {'id': 'dyeing', 'name': 'Dyeing Section'},
      'classification': {'label': 'Liquid fuel fire', 'guidance': 'Do NOT use water.'},
      'timeline': [
        {'at': '2026-09-25T06:40:19Z', 'what': 'Gas warning raised', 'detail': 'Above normal.'},
        {'at': '2026-09-25T06:40:23Z', 'what': 'Gas warning escalated to fire', 'detail': ''},
      ],
      'durations': {'warningToFireS': 4, 'fireToClassifiedS': 5, 'totalS': 12},
      'checkout': {'checkedOut': 3, 'peakOccupancy': 6, 'unaccounted': 3},
      'delivery': {'p50Ms': 412.0, 'p95Ms': 980.0, 'acknowledged': 2},
      'route': {'exitName': 'North door', 'lengthM': 13.6},
      'routeLatencyMs': 820.0,
      'caveats': ['Trained on simulation.'],
    };

    test('carries the notice the sensors gave, which is the point of the tier', () {
      final r = IncidentReport.fromJson(wire);
      expect(r.warningToFireS, 4);
      expect(r.escalatedFromWarning, isTrue);
    });

    test('carries both occupancy counts and the delivery percentiles', () {
      final r = IncidentReport.fromJson(wire);
      expect(r.checkout.checkedOut, 3);
      expect(r.checkout.peakOccupancy, 6);
      expect(r.deliveryP50Ms, 412.0);
      expect(r.deliveryP95Ms, 980.0);
    });

    test('a sparse report parses without inventing figures', () {
      final r = IncidentReport.fromJson({
        'id': 'inc_1',
        'severity': 'warning',
        'zone': {'name': 'Boiler Room'},
      });
      expect(r.warningToFireS, isNull);
      expect(r.deliveryP50Ms, isNull);
      expect(r.routeExitName, isNull);
      expect(r.timeline, isEmpty);
      expect(r.severity, IncidentSeverity.warning);
    });
  });

  group('the resolved screen', () {
    Incident evacuating({required int out, int? peak}) {
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
          detectedAt: now.subtract(const Duration(minutes: 1)),
        ),
        muster: const MusterRoll(present: 0, total: 0),
        checkout: CheckoutRoll(
          checkedOut: out,
          peakOccupancy: peak,
          unaccounted: peak == null ? null : (peak - out).clamp(0, peak),
        ),
      );
    }

    Future<void> pumpResolved(WidgetTester tester, Incident incident) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final router = buildRouter();
      await tester.pumpWidget(FireWatchApp(
        repository: MockFireRepository(incident: incident, live: true),
        router: router,
      ));
      await tester.pumpAndSettle();
      router.go('/resolved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('shows both counts, not one reconciled number', (tester) async {
      await pumpResolved(tester, evacuating(out: 2, peak: 5));
      expect(find.textContaining('Checked out · 2 people of 5'), findsOneWidget);
      expect(find.textContaining('3 not yet accounted for'), findsOneWidget);
    });

    testWidgets('an unknown head-count does not read as everyone being out',
        (tester) async {
      await pumpResolved(tester, evacuating(out: 2, peak: null));
      expect(find.textContaining('Head-count unavailable'), findsOneWidget);
      expect(find.textContaining('not yet accounted for'), findsNothing);
    });

    testWidgets('says so plainly when the camera count is fully matched',
        (tester) async {
      await pumpResolved(tester, evacuating(out: 5, peak: 5));
      expect(find.textContaining('Everyone the camera saw has checked out'),
          findsOneWidget);
    });
  });
}
