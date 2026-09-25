import 'package:firewatch/app.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:firewatch/data/mock/mock_data.dart';
import 'package:firewatch/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressions for the four-state model. Each of these was a real, shipped
/// behaviour that told the person holding the phone something untrue.
Incident _incident({
  required IncidentSeverity severity,
  Verification verification = Verification.confirmed,
  double confidence = 0.92,
  FireClassification? classification,
  String sensorSummary = '',
}) {
  final now = DateTime.now();
  final zone = MockData.zones(now).first;
  return Incident(
    id: 'inc_test',
    zone: zone,
    event: DetectionEvent(
      zoneId: zone.id,
      type: severity == IncidentSeverity.fire ? DetectionType.fire : DetectionType.smoke,
      detected: true,
      confidence: confidence,
      description: 'Readings above normal.',
      detectedAt: now.subtract(const Duration(seconds: 20)),
    ),
    muster: const MusterRoll(present: 2, total: 5),
    severity: severity,
    verification: verification,
    classification: classification,
    sensorSummary: sensorSummary,
  );
}

Widget _app(MockFireRepository repo) =>
    FireWatchApp(repository: repo, router: buildRouter());

/// Mount the app with reduce-motion on.
///
/// The screens already honour `MediaQuery.disableAnimations`, so turning it on
/// stops the perpetual pulse controllers and makes these tests deterministic
/// instead of racing an animation that never ends.
Future<void> _pumpApp(WidgetTester tester, MockFireRepository repo) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(_app(repo));
  await tester.pumpAndSettle();
}

/// Scroll the takeover's list until [finder] is built.
///
/// The incident screen is a `ListView`, so anything below the fold — the
/// guidance card sits under the detection panel and the floor plan — does not
/// exist in the tree until it is scrolled into range.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
    duration: const Duration(milliseconds: 20),
  );
}

/// Open a takeover and let its transition finish.
///
/// `pumpAndSettle` cannot be used past this point: the incident screen runs a
/// perpetual pulse animation and a one-second elapsed-time timer, so there is
/// never a frame where nothing is scheduled. Pumping a fixed span is both
/// deterministic and enough — the takeover transition is 320ms.
Future<void> _openTakeover(WidgetTester tester, String heroText) async {
  await tester.tap(find.text(heroText));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('wire parsing', () {
    test('an unknown severity reads as a fire, never as something quieter', () {
      expect(IncidentSeverity.fromWire(null), IncidentSeverity.fire);
      expect(IncidentSeverity.fromWire('something_new'), IncidentSeverity.fire);
      expect(IncidentSeverity.fromWire('gas_danger'), IncidentSeverity.gasDanger);
    });

    test('verification survives the round trip, including not_applicable', () {
      for (final v in Verification.values) {
        expect(Verification.fromWire(v.wire), v);
      }
    });

    test('severity comes from the field, never from the incident id', () {
      // An escalated warning keeps its `warn_` prefix even once it is a fire.
      final json = {
        'id': 'warn_abc123',
        'severity': 'fire',
        'zone': MockData.zones(DateTime.now()).first.toJson(),
        'event': {'type': 'fire', 'detected': true, 'confidence': 0.9},
        'muster': {'present': 1, 'total': 3},
      };
      expect(Incident.fromJson(json).severity, IncidentSeverity.fire);
    });

    test('classification parses the snake_case response sub-object', () {
      final c = FireClassification.fromJson({
        'fuelType': 'liquid_fuel',
        'label': 'Liquid fuel fire',
        'guidance': 'Do NOT use water.',
        'source': 'model',
        'trainedOn': 'simulation',
        'response': {
          'fire_class': 'B',
          'first_action': 'Raise the alarm.',
          'use': [
            {'agent': 'Foam (AFFF)', 'note': ''},
            {'agent': 'CO2', 'note': ''},
          ],
          'do_not_use': [
            {'agent': 'Water', 'why': 'spreads burning liquid'},
          ],
        },
      });
      expect(c.fireClass, 'B');
      expect(c.useAgents, ['Foam (AFFF)', 'CO2']);
      expect(c.avoidAgents, ['Water']);
      expect(c.isUnvalidated, isTrue);
      expect(c.isPending, isFalse);
    });

    test('an unavailable classification is pending, not a verdict', () {
      final c = FireClassification.fromJson(
          {'source': 'unavailable', 'fuelType': null, 'guidance': ''});
      expect(c.isPending, isTrue);
    });
  });

  group('confidence is suppressed where it is meaningless', () {
    test('a carbon-monoxide alarm carries 0.0 and must not display it', () {
      final co = _incident(severity: IncidentSeverity.gasDanger, confidence: 0.0);
      expect(co.hasMeaningfulConfidence, isFalse);
    });

    test('a confirmed fire still shows its figure', () {
      expect(_incident(severity: IncidentSeverity.fire).hasMeaningfulConfidence, isTrue);
    });
  });

  testWidgets('an open gas warning does not read "All clear"', (tester) async {
    await _pumpApp(tester, MockFireRepository(
      incident: _incident(
        severity: IncidentSeverity.warning,
        confidence: 0.0,
        sensorSummary: 'MQ-2 620 ppm (warn)',
      ),
      live: true,
    ));

    // The backend reports allClear: true alongside an open warning, on purpose.
    expect(find.text('All clear'), findsNothing);
    expect(find.text('⚠️ Gas levels rising'), findsOneWidget);
  });

  testWidgets('a gas alarm does not announce a flame, or a 0% confidence',
      (tester) async {
    await _pumpApp(tester, MockFireRepository(
      incident: _incident(severity: IncidentSeverity.gasDanger, confidence: 0.0),
      live: true,
    ));
    await _openTakeover(tester, '⚠️ Dangerous gas');

    expect(find.text('🔥 Fire detected'), findsNothing);
    expect(find.textContaining('0%'), findsNothing);
    expect(find.textContaining('Confirmed by 2 AI checks'), findsNothing);
    expect(find.textContaining('no camera confirmation'), findsOneWidget);
  });

  testWidgets('a fire confirmed without the scene model says so', (tester) async {
    await _pumpApp(tester, MockFireRepository(
      incident: _incident(
        severity: IncidentSeverity.fire,
        verification: Verification.unavailable,
      ),
      live: true,
    ));
    await _openTakeover(tester, '🔥 Fire detected');

    expect(find.textContaining('Confirmed by 2 AI checks'), findsNothing);
    expect(find.textContaining('Scene check unavailable'), findsOneWidget);
  });

  testWidgets('fuel guidance is shown verbatim, hedged and marked unvalidated',
      (tester) async {
    const guidance = 'Do NOT use water — it will spread burning liquid. '
        'Use foam, CO2 or dry powder.';
    await _pumpApp(tester, MockFireRepository(
      incident: _incident(
        severity: IncidentSeverity.fire,
        classification: const FireClassification(
          fuelType: 'liquid_fuel',
          label: 'Liquid fuel fire',
          guidance: guidance,
          source: 'model',
          trainedOn: 'simulation',
          fireClass: 'B',
        ),
      ),
      live: true,
    ));
    await _openTakeover(tester, '🔥 Fire detected');

    await _scrollTo(tester, find.text(guidance));
    expect(find.text(guidance), findsOneWidget);
    expect(find.textContaining('Likely:'), findsOneWidget);
    expect(find.text('unvalidated'), findsOneWidget);
  });

  testWidgets('a pending fuel verdict says so rather than showing a blank',
      (tester) async {
    await _pumpApp(tester, MockFireRepository(
      incident: _incident(
        severity: IncidentSeverity.fire,
        classification: const FireClassification(
          fuelType: null,
          label: 'Fire',
          guidance: '',
          source: 'unavailable',
        ),
      ),
      live: true,
    ));
    await _openTakeover(tester, '🔥 Fire detected');

    await _scrollTo(tester, find.text('Identifying fuel…'));
    expect(find.text('Identifying fuel…'), findsOneWidget);
  });
}
