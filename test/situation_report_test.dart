import 'package:firewatch/app.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:firewatch/data/mock/mock_data.dart';
import 'package:firewatch/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The situation report (RO3.1) as the phone renders it.
///
/// The backend has already removed anything the evidence contradicted. What the
/// app must still get right is the difference between a claim that was confirmed
/// and one that nothing could check — rendering those identically would undo the
/// point of validating before release.
SituationReport _report({
  required List<(String, String, String)> claims,
  String narrative = '',
  int withheld = 0,
}) =>
    SituationReport.fromJson({
      'claims': [
        for (final (id, text, cat) in claims)
          {'id': id, 'label': id, 'text': text, 'category': cat,
           'evidence': 'test', 'why': 'because'},
      ],
      'narrative': narrative,
      'grounding': {
        'claims': claims.length,
        'contradicted': withheld,
        'groundingAccuracy': 0.5,
      },
    });

Incident _incidentWith(SituationReport r) {
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
      description: 'Raw model sentence.',
      detectedAt: now.subtract(const Duration(seconds: 20)),
    ),
    muster: const MusterRoll(present: 1, total: 3),
    situationReport: r,
  );
}

Future<void> _openIncident(WidgetTester tester, Incident incident) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  // A tall surface so the whole incident screen is laid out at once. The screen
  // is a ListView, which builds lazily, so on the default 800x600 test surface
  // the report card sits below the fold and is never built — the finders would
  // then fail for a reason that has nothing to do with the report.
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

void main() {
  group('parsing', () {
    test('reads the five report elements with their verdicts', () {
      final r = _report(claims: [
        ('location', 'Location: Fabric Store, Main floor', 'supported'),
        ('material', 'Burning material: fabric rolls', 'supported'),
        ('size', 'Approximate size: small', 'unsupported'),
        ('smoke', 'Smoke: thick, black', 'supported'),
        ('people', 'People: 2 visible in the zone', 'supported'),
      ]);
      expect(r.claims.length, 5);
      expect(r.shown.length, 5);
      expect(r.hasUnverified, isTrue);
    });

    test('an unknown category is read as supported, never invented', () {
      expect(ClaimGrounding.fromWire('something_else'), ClaimGrounding.supported);
      expect(ClaimGrounding.fromWire(null), ClaimGrounding.supported);
      expect(ClaimGrounding.fromWire('unsupported'), ClaimGrounding.unsupported);
    });

    test('a contradicted claim is never shown, even if one slips through', () {
      // The backend strips these, but the app must not depend on that.
      final r = _report(claims: [
        ('location', 'Location: Fabric Store', 'supported'),
        ('people', 'People: none visible', 'contradicted'),
      ]);
      expect(r.claims.length, 2);
      expect(r.shown.length, 1);
      expect(r.shown.single.id, 'location');
    });

    test('an incident with no report parses to null', () {
      final inc = Incident.fromJson({
        'id': 'inc_1',
        'zone': {'id': 'fabric-store', 'name': 'Fabric Store'},
        'event': {'type': 'fire', 'confidence': 0.9},
        'muster': {'present': 1, 'total': 2},
      });
      expect(inc.situationReport, isNull);
    });
  });

  group('rendering', () {
    testWidgets('shows each element of the report', (tester) async {
      await _openIncident(tester, _incidentWith(_report(claims: [
        ('location', 'Location: Fabric Store, Main floor', 'supported'),
        ('material', 'Burning material: fabric rolls', 'supported'),
        ('smoke', 'Smoke: thick, black', 'supported'),
      ])));
      expect(find.text('SITUATION REPORT'), findsOneWidget);
      expect(find.text('Location: Fabric Store, Main floor'), findsOneWidget);
      expect(find.text('Burning material: fabric rolls'), findsOneWidget);
      expect(find.text('Smoke: thick, black'), findsOneWidget);
    });

    testWidgets('marks a claim nothing could check', (tester) async {
      await _openIncident(tester, _incidentWith(_report(claims: [
        ('location', 'Location: Fabric Store', 'supported'),
        ('size', 'Approximate size: moderate', 'unsupported'),
      ])));
      expect(find.text('unverified'), findsOneWidget);
      expect(find.textContaining('could not be checked'), findsOneWidget);
    });

    testWidgets('does not mark a claim the evidence confirmed', (tester) async {
      await _openIncident(tester, _incidentWith(_report(claims: [
        ('location', 'Location: Fabric Store', 'supported'),
        ('people', 'People: 2 visible in the zone', 'supported'),
      ])));
      expect(find.text('unverified'), findsNothing);
      expect(find.textContaining('could not be checked'), findsNothing);
    });

    testWidgets('admits when a statement was withheld', (tester) async {
      await _openIncident(tester, _incidentWith(_report(
        claims: [('location', 'Location: Fabric Store', 'supported')],
        withheld: 1,
      )));
      expect(find.textContaining('1 statement was withheld'), findsOneWidget);
    });

    testWidgets('falls back to the raw sentence when there is no report',
        (tester) async {
      final now = DateTime.now();
      final zone = MockData.zones(now).first;
      await _openIncident(
        tester,
        Incident(
          id: 'inc_test',
          zone: zone,
          event: DetectionEvent(
            zoneId: zone.id,
            type: DetectionType.fire,
            detected: true,
            confidence: 0.9,
            description: 'Raw model sentence.',
            detectedAt: now,
          ),
          muster: const MusterRoll(present: 1, total: 3),
        ),
      );
      expect(find.text('SITUATION REPORT'), findsNothing);
      expect(find.text('Raw model sentence.'), findsOneWidget);
    });
  });
}
