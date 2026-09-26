import 'dart:convert';
import 'dart:io';

import 'package:firewatch/data/models/models.dart';
import 'package:firewatch/shared/floor_plan/floor_plan_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firewatch/data/mock/mock_data.dart';

/// The route layer, and the contract it shares with the backend site files.
void main() {
  group('EvacRoute parsing', () {
    final wire = <String, dynamic>{
      'status': 'exit',
      'siteKey': 'industrial',
      'planRevision': '2026-09-25.1',
      'fireZoneId': 'fabric-store',
      'from': {'x': 163, 'y': 55},
      'hazard': {'x': 42, 'y': 66, 'radiusPx': 60},
      'polyline': [
        {'x': 163, 'y': 55},
        {'x': 163, 'y': 171},
        {'x': 333, 'y': 171},
      ],
      'exitId': 'exit-east',
      'exitName': 'EAST FIRE EXIT',
      'muster': {'x': 346, 'y': 171},
      'blockedExitIds': ['exit-north'],
      'lengthM': 29.3,
      'instruction': 'Leave through the east fire exit.',
    };

    test('reads the wire block the backend sends', () {
      final r = EvacRoute.fromJson(wire);
      expect(r.status, RouteStatus.exit);
      expect(r.polyline.length, 3);
      expect(r.polyline.last, const Offset(333, 171));
      expect(r.blockedExitIds, ['exit-north']);
      expect(r.hazardRadiusPx, 60);
      expect(r.isDrawable, isTrue);
    });

    test('an incident with no route is not an error', () {
      final inc = Incident.fromJson({
        'id': 'inc_1',
        'zone': {'id': 'fabric-store', 'name': 'Fabric Store'},
        'event': {'type': 'fire', 'confidence': 0.9},
        'muster': {'present': 1, 'total': 2},
        'route': null,
      });
      expect(inc.route, isNull);
    });

    test('an unknown status degrades to a route, never to a silent refuge', () {
      expect(RouteStatus.fromWire(null), RouteStatus.exit);
      expect(RouteStatus.fromWire('refuge'), RouteStatus.refuge);
    });

    test('rebuilds from the flat FCM payload, for when the network is down', () {
      final r = EvacRoute.fromFcm({
        'routeStatus': 'exit',
        'routeSiteKey': 'industrial',
        'routeExitName': 'EAST FIRE EXIT',
        'routeInstruction': 'Leave through the east fire exit.',
        'routeBlockedExits': 'exit-north',
        'routePolyline': '163,55;163,171;333,171',
        'routeHazard': '42,66,60',
        'routeMuster': '346,171',
        'routeLengthM': '29.3',
      });
      expect(r, isNotNull);
      expect(r!.polyline.length, 3);
      expect(r.polyline.first, const Offset(163, 55));
      expect(r.hazardAt, const Offset(42, 66));
      expect(r.musterAt, const Offset(346, 171));
      expect(r.blockedExitIds, ['exit-north']);
    });

    test('a push with no route yields null rather than an empty route', () {
      expect(EvacRoute.fromFcm({'zoneId': 'fabric-store'}), isNull);
    });

    test('equality tracks the polyline, so the painter repaints on a new route', () {
      final a = EvacRoute.fromJson(wire);
      final b = EvacRoute.fromJson(wire);
      final moved = EvacRoute.fromJson({
        ...wire,
        'polyline': [
          {'x': 163, 'y': 55},
          {'x': 163, 'y': 171},
        ],
      });
      expect(a, equals(b));
      expect(a, isNot(equals(moved)));
    });
  });

  group('FloorPlan', () {
    test('every drawing is filed under its own site key', () {
      // forSiteKey is the whole plan-selection mechanism now, so a drawing filed
      // under the wrong key would silently pair a route with another building.
      FloorPlan.byKey.forEach((key, plan) => expect(plan.siteKey, key));
      expect(FloorPlan.byKey.keys, containsAll(['home', 'industrial']));
    });

    test('a site with no drawing resolves to null, not to a default', () {
      // The screen turns null into "no route shown". A default would draw the
      // route on whichever building happened to be first.
      expect(FloorPlan.forSiteKey('warehouse-b'), isNull);
      expect(FloorPlan.forSiteKey(''), isNull);
      expect(FloorPlan.forSiteKey(null), isNull);
      expect(FloorPlan.forSiteKey('home'), FloorPlan.home);
      expect(FloorPlan.forSiteKey('industrial'), FloorPlan.industrial);
    });

    test('identity is site + revision, not sixty Rects', () {
      // shouldRepaint runs every frame, so equality must not walk the geometry.
      expect(FloorPlan.home, equals(FloorPlan.home));
      expect(FloorPlan.home.hashCode,
          Object.hash(FloorPlan.home.siteKey, FloorPlan.home.revision));
    });

    test('every mock zone has a room on the trial plan', () {
      // The other direction of the join above, and the one that was missing.
      // MockData once described the industrial zones while the phone defaulted
      // to the home plan, so roomForZone returned null for every zone and the
      // plan quietly drew no room at all. Nothing failed, because nothing asked.
      for (final z in MockData.zones(DateTime.now())) {
        expect(FloorPlan.home.roomForZone(z.id), isNotNull,
            reason: 'no room draws zone ${z.id}');
      }
    });

    test('exit ids are unique within every drawing', () {
      for (final plan in FloorPlan.byKey.values) {
        final ids = plan.exits.map((e) => e.id).toList();
        expect(ids.toSet().length, ids.length, reason: plan.siteKey);
      }
    });

    test('every drawn element sits inside its design space', () {
      for (final plan in FloorPlan.byKey.values) {
        final bounds = Offset.zero & plan.designSize;
        for (final r in plan.rooms) {
          expect(bounds.contains(r.rect.topLeft), isTrue,
              reason: '${plan.siteKey}/${r.id}');
          expect(bounds.contains(r.rect.bottomRight), isTrue,
              reason: '${plan.siteKey}/${r.id}');
        }
        for (final e in plan.exits) {
          expect(bounds.contains(e.bar.center), isTrue,
              reason: '${plan.siteKey}/${e.id}');
        }
      }
    });
  });

  // ── The mirror contract with alert-service/sites/*.json ───────────────────
  //
  // The backend owns the graph and this app owns the drawing. They agree on
  // exactly two things, and if either drifts a perfectly correct route gets
  // painted through the walls of a different building. Nothing else checks this,
  // so this test does.
  group('site files agree with the drawings', () {
    Map<String, dynamic>? load(String key) {
      final f = File('../fire_detection_and_classification_web_app/'
          'alert-service/sites/$key.json');
      if (!f.existsSync()) return null;
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }

    for (final entry in FloorPlan.byKey.entries) {
      test('${entry.key}: exit ids and coordinate space match', () {
        final site = load(entry.key);
        if (site == null) {
          markTestSkipped('sibling backend repo not checked out');
          return;
        }
        final plan = entry.value;

        final serverExits =
            (site['exits'] as List).map((e) => e['id'] as String).toSet();
        expect(plan.exits.map((e) => e.id).toSet(), serverExits,
            reason: 'a blocked exit would not find its bar');

        final render = site['render'] as Map<String, dynamic>;
        expect(render['designW'], plan.designSize.width,
            reason: 'the route would be drawn at the wrong scale');
        expect(render['designH'], plan.designSize.height);

        expect(site['revision'], plan.revision,
            reason: 'revision is how the stored analysis knows which building '
                'a route was computed against');

        final serverZones =
            (site['zones'] as List).map((z) => z['id'] as String).toSet();
        for (final r in plan.rooms) {
          if (r.zoneId != null) {
            expect(serverZones, contains(r.zoneId), reason: '${entry.key}/${r.id}');
          }
        }
      });
    }
  });
}
