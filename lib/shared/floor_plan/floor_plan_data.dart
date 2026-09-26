import 'package:flutter/painting.dart';

/// Which schematic to draw.
enum FloorPlanMode {
  /// Incident: the burning room hatched and avoided, YOU marker, marching safe
  /// route, muster point, and every cut exit struck through.
  incidentRoute,

  /// Zone detail: one room highlighted safe, no route / fire / muster.
  zoneSafe,
}

/// A facility drawing: rooms, doors, exit bars and labels, in its own design
/// space. The painter scales it to whatever width it is given.
///
/// THE APP OWNS THE ARTWORK; THE BACKEND OWNS THE GRAPH. Rooms, doors and exit
/// bars are const data here, because a generic renderer fed server geometry
/// looks like a wireframe and this screen is read under time pressure. Only the
/// parts that change with the fire — which way to walk, which doors are cut —
/// arrive over the wire.
///
/// **This is a mirrored contract** with `alert-service/sites/<key>.json`, and
/// it holds on exactly two things:
///
///  * the **exit ids**, which is how a server-blocked exit finds its bar here;
///  * the **coordinate space** — [designSize] and the site file's `pxPerM` must
///    describe the same building, or a perfectly correct route is drawn through
///    the walls of a different one.
///
/// Change either side and change the other. Same rule as
/// `zones_seed.py` ↔ `mock_data.dart`.
class FloorPlan {
  const FloorPlan({
    required this.siteKey,
    required this.revision,
    required this.designSize,
    required this.shell,
    required this.rooms,
    required this.walkways,
    required this.guides,
    required this.doors,
    required this.exits,
    required this.defaultRoute,
    required this.youAt,
    required this.fireAt,
    required this.musterAt,
  });

  final String siteKey;
  final String revision;
  final Size designSize;
  final Rect shell;
  final List<PlanRoom> rooms;
  final List<Rect> walkways;
  final List<PlanGuide> guides;
  final List<Rect> doors;
  final List<PlanExit> exits;

  /// The picture drawn when no server route is available — a dead backend, an
  /// old incident, the offline demo. It is the frame this app shipped with, so
  /// degrading to it looks deliberate rather than broken.
  final List<Offset> defaultRoute;
  final Offset youAt;
  final Offset fireAt;
  final Offset musterAt;

  PlanRoom? roomForZone(String? zoneId) {
    if (zoneId == null) return null;
    for (final r in rooms) {
      if (r.zoneId == zoneId) return r;
    }
    return null;
  }

  PlanExit? exitById(String? id) {
    if (id == null) return null;
    for (final e in exits) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Identity is site + revision, not deep equality.
  ///
  /// `shouldRepaint` runs every frame, and deep-comparing sixty-odd [Rect]s at
  /// 60 fps is pure waste. These are immutable const tables keyed by revision,
  /// so equal revision means identical geometry by construction.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FloorPlan &&
          other.siteKey == siteKey &&
          other.revision == revision);

  @override
  int get hashCode => Object.hash(siteKey, revision);

  // ── Industrial unit — the demo facility ──────────────────────────────────────────
  //
  // Transcribed unchanged from the original prototype, and the reason
  // sites/industrial.json uses 10 px/m: at that scale these literals describe a
  // 36.0 × 34.8 m floor, so the graph and this drawing are the same building.
  static const industrial = FloorPlan(
    siteKey: 'industrial',
    revision: '2026-09-25.1',
    designSize: Size(360, 348),
    shell: Rect.fromLTWH(14, 14, 318, 312),
    rooms: [
      PlanRoom('fabric-store', Rect.fromLTWH(18, 18, 130, 66), 'Fabric Store',
          zoneId: 'fabric-store'),
      PlanRoom('cutting-floor', Rect.fromLTWH(18, 88, 130, 66), 'Cutting Floor',
          zoneId: 'cutting-floor'),
      PlanRoom('dyeing', Rect.fromLTWH(178, 18, 150, 66), 'Dyeing Section',
          zoneId: 'dyeing'),
      PlanRoom('warehouse', Rect.fromLTWH(178, 88, 150, 66), 'Warehouse',
          zoneId: 'warehouse'),
      PlanRoom('finishing', Rect.fromLTWH(18, 188, 130, 58), 'Finishing',
          zoneId: 'finishing'),
      PlanRoom('boiler', Rect.fromLTWH(18, 252, 130, 68), 'Boiler Room',
          zoneId: 'boiler'),
      PlanRoom('sewing-a', Rect.fromLTWH(178, 188, 150, 58), 'Sewing Floor',
          zoneId: 'sewing-a'),
      // No detector in Packing & Dispatch. `zoneId: null` rather than a made-up
      // id: inventing one would assert monitoring that does not exist.
      PlanRoom('packing', Rect.fromLTWH(178, 252, 150, 68), 'Packing &',
          line2: 'Dispatch'),
    ],
    walkways: [
      Rect.fromLTWH(150, 16, 26, 308),
      Rect.fromLTWH(16, 158, 314, 26),
    ],
    guides: [
      PlanGuide(Offset(163, 18), Offset(163, 322)),
      PlanGuide(Offset(18, 171), Offset(328, 171)),
    ],
    doors: [
      Rect.fromLTWH(145, 48, 6, 14),
      Rect.fromLTWH(145, 112, 6, 14),
      Rect.fromLTWH(175, 48, 6, 14),
      Rect.fromLTWH(175, 112, 6, 14),
      Rect.fromLTWH(145, 210, 6, 14),
      Rect.fromLTWH(145, 280, 6, 14),
      Rect.fromLTWH(175, 210, 6, 14),
      Rect.fromLTWH(175, 280, 6, 14),
      Rect.fromLTWH(118, 152, 14, 6),
      Rect.fromLTWH(205, 152, 14, 6),
    ],
    exits: [
      PlanExit(
        id: 'exit-east', name: 'EAST FIRE EXIT', primary: true,
        bar: Rect.fromLTWH(329, 158, 9, 26),
        labelCx: 298, labelBaselineY: 150, musterAt: Offset(346, 171),
      ),
      PlanExit(
        id: 'exit-north', name: 'North door',
        bar: Rect.fromLTWH(46, 9, 38, 9),
        labelCx: 65, labelBaselineY: 6, musterAt: Offset(65, 13),
      ),
      PlanExit(
        id: 'exit-south', name: 'South door',
        bar: Rect.fromLTWH(58, 322, 34, 9),
        labelCx: 75, labelBaselineY: 342, musterAt: Offset(75, 326),
      ),
      PlanExit(
        id: 'exit-bay', name: 'Loading bay',
        bar: Rect.fromLTWH(238, 322, 48, 9),
        labelCx: 262, labelBaselineY: 342, musterAt: Offset(262, 326),
      ),
    ],
    defaultRoute: [
      Offset(138, 55),
      Offset(163, 55),
      Offset(163, 171),
      Offset(336, 171),
    ],
    youAt: Offset(138, 55),
    fireAt: Offset(42, 66),
    musterAt: Offset(346, 171),
  );

  /// Every drawing this build has, keyed by the site key the backend stamps on
  /// a route (`alert-service/sites/<key>.json`).
  static const byKey = <String, FloorPlan>{
    'home': home,
    'industrial': industrial,
  };

  /// The drawing for [key], or null when this build has none for it.
  ///
  /// NULL IS A REAL ANSWER, NOT A FAILURE TO HANDLE. A backend pointed at a site
  /// this app was never given artwork for must make the route unavailable and say
  /// so, because a polyline only means anything in the coordinate space it was
  /// computed in. There is deliberately no "closest" or default plan here: home
  /// is 25 px/m and industrial is 10 px/m, so the same coordinates land 2.5x
  /// further into one building than the other, and guessing would draw a
  /// confident path through the wrong walls.
  static FloorPlan? forSiteKey(String? key) =>
      (key == null || key.isEmpty) ? null : byKey[key];

  // ── Home — the facility the trials actually ran in ──────────────────────
  //
  // Traced from the hand sketch. Eight areas on a 332 × 242 px shell at 25 px/m,
  // so 13.28 × 9.68 m. Three of the four outer-wall marks on the sketch are
  // windows; the two exterior doors are the front door off the dining area and
  // the back door off the verander.
  //
  // Every bedroom and the kitchen has exactly ONE door, onto a shared space.
  // That is why a fire in the living area or the dining area can leave a room
  // with nowhere to go, and why the refuge branch is not a corner case here.
  static const home = FloorPlan(
    siteKey: 'home',
    revision: '2026-09-25.1',
    designSize: Size(360, 280),
    shell: Rect.fromLTWH(14, 14, 332, 242),
    rooms: [
      PlanRoom('kitchen', Rect.fromLTWH(14, 14, 75, 82), 'Kitchen',
          zoneId: 'kitchen'),
      PlanRoom('bedroom-west', Rect.fromLTWH(14, 96, 75, 78), 'Bedroom',
          zoneId: 'bedroom-west'),
      PlanRoom('bedroom-southwest', Rect.fromLTWH(14, 174, 75, 82), 'Bedroom',
          zoneId: 'bedroom-southwest'),
      PlanRoom('dining', Rect.fromLTWH(89, 14, 178, 77), 'Dining Area',
          zoneId: 'dining'),
      PlanRoom('living', Rect.fromLTWH(89, 91, 178, 81), 'Living Area',
          zoneId: 'living'),
      PlanRoom('verander', Rect.fromLTWH(89, 172, 178, 84), 'Verander',
          zoneId: 'verander'),
      PlanRoom('bedroom-northeast', Rect.fromLTWH(267, 14, 79, 76), 'Bedroom',
          zoneId: 'bedroom-northeast'),
      PlanRoom('bedroom-southeast', Rect.fromLTWH(267, 90, 79, 166), 'Bedroom',
          zoneId: 'bedroom-southeast'),
    ],
    // A house has no corridors: the dining/living/verander chain is the
    // circulation, and it is drawn as rooms because that is what it is.
    walkways: [],
    guides: [],
    doors: [
      Rect.fromLTWH(86, 47, 6, 14),    // kitchen  ↔ dining
      Rect.fromLTWH(86, 127, 6, 14),   // bedroom  ↔ living
      Rect.fromLTWH(86, 207, 6, 14),   // bedroom  ↔ verander
      Rect.fromLTWH(264, 40, 6, 14),   // dining   ↔ bedroom (NE)
      Rect.fromLTWH(264, 113, 6, 14),  // living   ↔ bedroom (SE)
      Rect.fromLTWH(233, 88, 14, 6),   // dining   ↔ living (wide opening)
      Rect.fromLTWH(189, 169, 14, 6),  // living   ↔ verander (wide opening)
    ],
    exits: [
      PlanExit(
        id: 'exit-north', name: 'FRONT DOOR', primary: true,
        bar: Rect.fromLTWH(159, 9, 28, 9),
        labelCx: 173, labelBaselineY: 6, musterAt: Offset(173, 13),
      ),
      PlanExit(
        id: 'exit-south', name: 'BACK DOOR', primary: true,
        bar: Rect.fromLTWH(217, 252, 28, 9),
        labelCx: 231, labelBaselineY: 268, musterAt: Offset(231, 256),
      ),
    ],
    defaultRoute: [
      Offset(173, 130),
      Offset(196, 172),
      Offset(173, 214),
      Offset(231, 256),
    ],
    youAt: Offset(173, 130),
    fireAt: Offset(130, 130),
    musterAt: Offset(231, 256),
  );
}

/// One drawn room. [id] is the drawing's own id; [zoneId] is the monitored zone
/// it corresponds to, or null where there is no detector.
class PlanRoom {
  const PlanRoom(this.id, this.rect, this.line1, {this.line2, this.zoneId});

  final String id;
  final Rect rect;
  final String line1;
  final String? line2;

  /// The monitored zone this room is, or null where there is no detector.
  final String? zoneId;

  /// Where the "clear" tick goes on the zone-detail plan. Derived rather than
  /// hard-coded so it follows whichever room is in focus.
  Offset get checkAt => Offset(rect.left + 56, rect.top + 52);
}

/// A dashed centre-line hint along a corridor.
class PlanGuide {
  const PlanGuide(this.from, this.to);
  final Offset from;
  final Offset to;
}

/// A way out, and where its bar and label sit on the drawing.
///
/// [id] must match an exit id in the matching `alert-service/sites/*.json`, or a
/// server-blocked exit will not find its bar and will silently draw as open.
class PlanExit {
  const PlanExit({
    required this.id,
    required this.name,
    required this.bar,
    required this.labelCx,
    required this.labelBaselineY,
    required this.musterAt,
    this.primary = false,
  });

  final String id;
  final String name;
  final Rect bar;
  final double labelCx;
  final double labelBaselineY;
  final Offset musterAt;

  /// Drawn in the emphatic "fire exit" style rather than as a plain door.
  final bool primary;
}
