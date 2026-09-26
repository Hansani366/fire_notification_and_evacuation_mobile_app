/// Domain models for the FireWatch client.
///
/// Field names mirror the real detection backend so this UI can be wired to it
/// without reshaping: the VLM service returns `{detected, type, description}`
/// and YOLO returns a `confidence` (0–1). The JSON here matches the
/// `alert-service` contract (see `mid-demo-vision-system/alert-service`).
library;

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart' show debugPrint, listEquals;

// ── JSON parse helpers (tolerant of nulls / string-encoded numbers) ──────────
double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
DateTime _asDate(dynamic v) =>
    v == null ? DateTime.now() : (DateTime.tryParse('$v')?.toLocal() ?? DateTime.now());

/// What the two-stage pipeline reports (`type` from the VLM, `null` → [none]).
enum DetectionType {
  fire,
  smoke,
  both,
  none;

  String get label => switch (this) {
        DetectionType.fire => 'Fire',
        DetectionType.smoke => 'Smoke',
        DetectionType.both => 'Both',
        DetectionType.none => 'None',
      };

  String get wire => name; // fire|smoke|both|none

  static DetectionType fromWire(String? s) => switch (s) {
        'fire' => DetectionType.fire,
        'smoke' => DetectionType.smoke,
        'both' => DetectionType.both,
        _ => DetectionType.none,
      };
}

/// Which alarm tier an incident is, per the four-state model.
///
/// [warning] is gas rising with nothing visible: informational, never a siren.
/// [gasDanger] is dangerous gas, still nothing visible — it DOES alarm, because
/// a camera cannot see carbon monoxide. [fire] is a flame confirmed on camera.
///
/// Defaults to [fire] on an unknown wire value so an incident recorded before
/// this field existed still reads as a fire rather than silently downgrading.
enum IncidentSeverity {
  warning,
  gasDanger,
  fire;

  /// True when this tier sounds the alarm and calls for evacuation.
  bool get isAlarm => this != IncidentSeverity.warning;

  /// True when nothing was visible on camera — the readings are the whole report.
  bool get isSensorOnly => this != IncidentSeverity.fire;

  String get wire => switch (this) {
        IncidentSeverity.warning => 'warning',
        IncidentSeverity.gasDanger => 'gas_danger',
        IncidentSeverity.fire => 'fire',
      };

  static IncidentSeverity fromWire(String? s) => switch (s) {
        'warning' => IncidentSeverity.warning,
        'gas_danger' => IncidentSeverity.gasDanger,
        _ => IncidentSeverity.fire,
      };
}

/// What the vision-language model had to say (Algorithm 3).
///
/// [unavailable] is **not** a rejection: a fire box with sensors above normal
/// still confirms a fire when the model cannot be reached, and the incident
/// records that it stands on detection evidence alone. [notApplicable] is tier
/// 1b, where there was no camera detection to verify in the first place.
enum Verification {
  confirmed,
  rejected,
  unavailable,
  notApplicable;

  /// True only when two independent checks actually agreed. The trust badge
  /// must never claim more than this.
  bool get isDoubleChecked => this == Verification.confirmed;

  String get wire => switch (this) {
        Verification.confirmed => 'confirmed',
        Verification.rejected => 'rejected',
        Verification.unavailable => 'unavailable',
        Verification.notApplicable => 'not_applicable',
      };

  static Verification fromWire(String? s) => switch (s) {
        'rejected' => Verification.rejected,
        'unavailable' => Verification.unavailable,
        'not_applicable' => Verification.notApplicable,
        _ => Verification.confirmed,
      };
}

/// A zone's resting monitoring state.
enum ZoneStatus {
  clear,
  smoke,
  fire;

  String get label => switch (this) {
        ZoneStatus.clear => 'Clear',
        ZoneStatus.smoke => 'Smoke',
        ZoneStatus.fire => 'Fire',
      };

  bool get isAlert => this == ZoneStatus.fire;
  bool get isWarn => this == ZoneStatus.smoke;

  String get wire => name; // clear|smoke|fire

  static ZoneStatus fromWire(String? s) => switch (s) {
        'fire' => ZoneStatus.fire,
        'smoke' => ZoneStatus.smoke,
        _ => ZoneStatus.clear,
      };
}

/// How a past incident ended (the history badge).
enum Resolution {
  userConfirmed,
  autoCleared,
  falseAlarm;

  String get label => switch (this) {
        Resolution.userConfirmed => 'User-confirmed',
        Resolution.autoCleared => 'Auto-cleared',
        Resolution.falseAlarm => 'False alarm',
      };

  String get wire => switch (this) {
        Resolution.userConfirmed => 'user_confirmed',
        Resolution.autoCleared => 'auto_cleared',
        Resolution.falseAlarm => 'false_alarm',
      };

  static Resolution fromWire(String? s) => switch (s) {
        'user_confirmed' => Resolution.userConfirmed,
        'false_alarm' => Resolution.falseAlarm,
        _ => Resolution.autoCleared,
      };
}

/// State of a single scene-AI note on the history timeline.
enum SceneState {
  fire,
  smoke,
  cleared;

  String get wire => name; // fire|smoke|cleared

  static SceneState fromWire(String? s) => switch (s) {
        'fire' => SceneState.fire,
        'smoke' => SceneState.smoke,
        _ => SceneState.cleared,
      };
}

/// Which schematic glyph represents a zone on the dashboard tile.
enum ZoneGlyph {
  fabricRoll,
  scissors,
  iron,
  boiler,
  dyeing,
  warehouse,
  finishing,
  // Domestic zones, for the trial facility. Without these, every room in the
  // house fell through `fromWire`'s fallback and rendered as a fabric roll —
  // silently, with no crash and no warning, so nobody would notice until the
  // plan was on a screen in front of somebody.
  kitchen,
  bedroom,
  dining,
  living,
  verander,

  /// A glyph this build does not know, and one it draws as a plain room.
  ///
  /// AN UNKNOWN GLYPH MUST LOOK UNKNOWN. Anything unrecognised used to become a
  /// fabric roll — silently, with no crash and no log — so a zone added to
  /// `zones_seed.py` with a glyph this app has never heard of appeared as a
  /// bolt of cloth in a bedroom, and nobody would find out until the tile was
  /// on a screen in front of somebody. A neutral icon is a visible question
  /// rather than a confident wrong answer.
  unknown;

  String get wire => name;

  static ZoneGlyph fromWire(String? s) {
    if (s == null || s.isEmpty) return ZoneGlyph.unknown;
    try {
      return ZoneGlyph.values.byName(s);
    } catch (_) {
      debugPrint('[ZoneGlyph] unknown glyph "$s" — drawing it as a plain room');
      return ZoneGlyph.unknown;
    }
  }
}

/// A monitored area watched by one detector.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.floor,
    required this.detectorId,
    required this.status,
    required this.lastScanAt,
    required this.glyph,
  });

  final String id;
  final String name;
  final String floor;
  final String detectorId; // e.g. "Detector 01"
  final ZoneStatus status;
  final DateTime lastScanAt;
  final ZoneGlyph glyph;

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        floor: j['floor'] as String? ?? '',
        detectorId: j['detectorId'] as String? ?? '',
        status: ZoneStatus.fromWire(j['status'] as String?),
        lastScanAt: _asDate(j['lastScanAt']),
        glyph: ZoneGlyph.fromWire(j['glyph'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'floor': floor,
        'detectorId': detectorId,
        'status': status.wire,
        'lastScanAt': lastScanAt.toUtc().toIso8601String(),
        'glyph': glyph.wire,
      };
}

/// A live detection record — the shape the backend delivers.
class DetectionEvent {
  const DetectionEvent({
    required this.zoneId,
    required this.type,
    required this.detected,
    required this.confidence,
    required this.description,
    required this.detectedAt,
  });

  final String zoneId;
  final DetectionType type;
  final bool detected; // VLM confirmation (stage 2)
  final double confidence; // YOLO score, 0..1 (stage 1)
  final String description; // VLM scene text
  final DateTime detectedAt;

  int get confidencePct => (confidence * 100).round();

  factory DetectionEvent.fromJson(Map<String, dynamic> j) => DetectionEvent(
        zoneId: j['zoneId'] as String? ?? '',
        type: DetectionType.fromWire(j['type'] as String?),
        detected: j['detected'] as bool? ?? false,
        confidence: _asDouble(j['confidence']),
        description: j['description'] as String? ?? '',
        detectedAt: _asDate(j['detectedAt']),
      );

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'type': type.wire,
        'detected': detected,
        'confidence': confidence,
        'description': description,
        'detectedAt': detectedAt.toUtc().toIso8601String(),
      };
}

/// Head-count at the muster point during an incident.
class MusterRoll {
  const MusterRoll({required this.present, required this.total});

  final int present;
  final int total;

  int get missing => total - present;

  factory MusterRoll.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const MusterRoll(present: 42, total: 45);
    return MusterRoll(present: _asInt(j['present']), total: _asInt(j['total']));
  }

  Map<String, dynamic> toJson() => {'present': present, 'total': total};
}

/// How many people the camera can see in the zone.
///
/// Both fields are nullable and null is meaningful: it says the human detector
/// had nothing to report, which is **not** the same as an empty room.
class Occupancy {
  const Occupancy({this.current, this.peak});

  final int? current;
  final int? peak;

  bool get isKnown => current != null;

  factory Occupancy.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Occupancy();
    return Occupancy(
      current: j['current'] == null ? null : _asInt(j['current']),
      peak: j['peak'] == null ? null : _asInt(j['peak']),
    );
  }

  Map<String, dynamic> toJson() => {'current': current, 'peak': peak};
}

/// What is burning, and what to fight it with.
///
/// The `guidance` sentence is rendered **verbatim**. It is never rebuilt from
/// [fuelType] on this side: the dashboard, the incident record and the phone all
/// read one table in the backend (`extinguishers.py`) precisely so they cannot
/// end up giving three different answers about the same fire.
///
/// Both models behind this were trained on CFAST simulation and have never seen
/// a recorded fire, which is what [trainedOn] says. Show it.
class FireClassification {
  const FireClassification({
    required this.fuelType,
    required this.label,
    required this.guidance,
    required this.source,
    this.confidence,
    this.trainedOn = '',
    this.fireClass = '',
    this.firstAction = '',
    this.useAgents = const [],
    this.avoidAgents = const [],
  });

  final String? fuelType; // gas_fire | liquid_fuel | solid_combustible
  final String label;
  final String guidance;
  final String source; // model | unavailable
  final double? confidence;
  final String trainedOn;
  final String fireClass; // A | B | C
  final String firstAction;
  final List<String> useAgents;
  final List<String> avoidAgents;

  /// True while the sensors are still reading clean air. A blank card looks
  /// like a bug, so the UI shows "identifying fuel…" instead.
  bool get isPending => source != 'model' || fuelType == null;

  /// True when the verdict has not been validated against real fire.
  bool get isUnvalidated => trainedOn == 'simulation';

  /// `response` comes straight from the backend's guidance table, so its keys
  /// are snake_case — unlike every other object on this wire.
  static List<String> _agents(dynamic list, String key) =>
      (list as List<dynamic>? ?? const [])
          .map((e) => (e is Map ? e[key] : null) as String? ?? '')
          .where((a) => a.isNotEmpty)
          .toList();

  factory FireClassification.fromJson(Map<String, dynamic> j) {
    final r = j['response'] as Map<String, dynamic>?;
    return FireClassification(
      fuelType: j['fuelType'] as String?,
      label: j['label'] as String? ?? 'Fire',
      guidance: j['guidance'] as String? ?? '',
      source: j['source'] as String? ?? 'unavailable',
      confidence: j['confidence'] == null ? null : _asDouble(j['confidence']),
      trainedOn: j['trainedOn'] as String? ?? '',
      fireClass: r?['fire_class'] as String? ?? '',
      firstAction: r?['first_action'] as String? ?? '',
      useAgents: _agents(r?['use'], 'agent'),
      avoidAgents: _agents(r?['do_not_use'], 'agent'),
    );
  }

  Map<String, dynamic> toJson() => {
        'fuelType': fuelType,
        'label': label,
        'guidance': guidance,
        'source': source,
        'confidence': confidence,
        'trainedOn': trainedOn,
      };
}

/// How the route generator answered.
enum RouteStatus {
  /// A way out was found.
  exit,

  /// No exit was reachable without passing the fire, so the answer is to shelter
  /// in place. A refusal is a correct answer — walking somebody through a fire
  /// because the alternative was admitting defeat is not.
  refuge;

  static RouteStatus fromWire(String? s) =>
      s == 'refuge' ? RouteStatus.refuge : RouteStatus.exit;
}

/// The escape route the backend generated for this fire.
///
/// Carries only what changes with the fire — where to walk, which doors are cut.
/// The building itself is const data in [FloorPlan]; see the mirror-contract note
/// there. Coordinates are already in the drawing's design space, so nothing here
/// needs converting before it is painted.
class EvacRoute {
  const EvacRoute({
    required this.status,
    required this.siteKey,
    required this.planRevision,
    required this.fireZoneId,
    required this.from,
    required this.hazardAt,
    required this.hazardRadiusPx,
    required this.polyline,
    required this.blockedExitIds,
    required this.instruction,
    this.exitId,
    this.exitName,
    this.musterAt,
    this.lengthM = 0,
    this.originReanchored = false,
  });

  final RouteStatus status;
  final String siteKey;
  final String planRevision;
  final String fireZoneId;
  final Offset from;
  final Offset hazardAt;
  final double hazardRadiusPx;
  final List<Offset> polyline;
  final List<String> blockedExitIds;
  final String instruction;
  final String? exitId;
  final String? exitName;
  final Offset? musterAt;
  final double lengthM;

  /// True when the occupant's own position was inside the hazard, so the route
  /// starts from the first reachable point outside it instead.
  final bool originReanchored;

  bool get isRefuge => status == RouteStatus.refuge;

  /// A route needs at least two points to be a walk rather than a dot.
  bool get isDrawable => polyline.length >= 2;

  static Offset _pt(dynamic j) => j is Map
      ? Offset(_asDouble(j['x']), _asDouble(j['y']))
      : Offset.zero;

  factory EvacRoute.fromJson(Map<String, dynamic> j) => EvacRoute(
        status: RouteStatus.fromWire(j['status'] as String?),
        siteKey: j['siteKey'] as String? ?? '',
        planRevision: j['planRevision'] as String? ?? '',
        fireZoneId: j['fireZoneId'] as String? ?? '',
        from: _pt(j['from']),
        hazardAt: _pt(j['hazard']),
        hazardRadiusPx: j['hazard'] is Map
            ? _asDouble((j['hazard'] as Map)['radiusPx'])
            : 0,
        polyline: (j['polyline'] as List<dynamic>? ?? const [])
            .map(_pt)
            .toList(growable: false),
        blockedExitIds: (j['blockedExitIds'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(growable: false),
        instruction: j['instruction'] as String? ?? '',
        exitId: j['exitId'] as String?,
        exitName: j['exitName'] as String?,
        musterAt: j['muster'] == null ? null : _pt(j['muster']),
        lengthM: _asDouble(j['lengthM']),
        originReanchored: j['originReanchored'] as bool? ?? false,
      );

  /// Rebuild from an FCM `data` payload, where everything is a flat string.
  ///
  /// This is what lets a route draw with **no network at all**: the phone already
  /// holds the building, so the push only has to carry the few hundred bytes that
  /// change. Returns null when the push carried no route.
  static EvacRoute? fromFcm(Map<String, dynamic> d) {
    final status = (d['routeStatus'] as String?) ?? '';
    if (status.isEmpty) return null;
    final pts = ((d['routePolyline'] as String?) ?? '')
        .split(';')
        .where((p) => p.contains(','))
        .map((p) {
          final xy = p.split(',');
          return Offset(double.tryParse(xy[0]) ?? 0, double.tryParse(xy[1]) ?? 0);
        })
        .toList(growable: false);
    final hazard = ((d['routeHazard'] as String?) ?? '').split(',');
    final muster = ((d['routeMuster'] as String?) ?? '').split(',');
    return EvacRoute(
      status: RouteStatus.fromWire(status),
      siteKey: (d['routeSiteKey'] as String?) ?? '',
      planRevision: (d['routePlanRevision'] as String?) ?? '',
      fireZoneId: (d['zoneId'] as String?) ?? '',
      from: pts.isNotEmpty ? pts.first : Offset.zero,
      hazardAt: hazard.length >= 2
          ? Offset(double.tryParse(hazard[0]) ?? 0, double.tryParse(hazard[1]) ?? 0)
          : Offset.zero,
      hazardRadiusPx: hazard.length >= 3 ? (double.tryParse(hazard[2]) ?? 0) : 0,
      polyline: pts,
      blockedExitIds: ((d['routeBlockedExits'] as String?) ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      instruction: (d['routeInstruction'] as String?) ?? '',
      exitName: (d['routeExitName'] as String?),
      musterAt: muster.length >= 2
          ? Offset(double.tryParse(muster[0]) ?? 0, double.tryParse(muster[1]) ?? 0)
          : null,
      lengthM: double.tryParse('${d['routeLengthM']}') ?? 0,
    );
  }

  /// Real value equality here, unlike [FloorPlan]: this is a handful of points
  /// and it genuinely changes while the plan does not, so `shouldRepaint` has to
  /// be able to see the difference.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvacRoute &&
          other.status == status &&
          other.exitId == exitId &&
          other.planRevision == planRevision &&
          other.hazardAt == hazardAt &&
          other.from == from &&
          listEquals(other.polyline, polyline) &&
          listEquals(other.blockedExitIds, blockedExitIds));

  @override
  int get hashCode => Object.hash(status, exitId, planRevision, hazardAt, from,
      Object.hashAll(polyline), Object.hashAll(blockedExitIds));
}

/// Who has said they are out, next to what the camera can still see.
///
/// TWO INSTRUMENTS, NOT ONE NUMBER. [checkedOut] is people who tapped; the
/// occupancy figures are what one camera can see. They measure the same
/// evacuation and they will disagree, and the disagreement is the point — it is
/// how you find out the camera missed somebody behind a rack, or is counting a
/// coat on a chair. Neither is corrected against the other.
class CheckoutRoll {
  const CheckoutRoll({
    this.checkedOut = 0,
    this.peakOccupancy,
    this.currentOccupancy,
    this.unaccounted,
  });

  final int checkedOut;
  final int? peakOccupancy;
  final int? currentOccupancy;

  /// Peak head-count minus check-outs, or null when the camera never had a
  /// number. Null must never render as "everybody is out".
  final int? unaccounted;

  bool get isKnown => peakOccupancy != null;

  factory CheckoutRoll.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const CheckoutRoll();
    return CheckoutRoll(
      checkedOut: _asInt(j['checkedOut']),
      peakOccupancy: j['peakOccupancy'] == null ? null : _asInt(j['peakOccupancy']),
      currentOccupancy:
          j['currentOccupancy'] == null ? null : _asInt(j['currentOccupancy']),
      unaccounted: j['unaccounted'] == null ? null : _asInt(j['unaccounted']),
    );
  }

  Map<String, dynamic> toJson() => {
        'checkedOut': checkedOut,
        'peakOccupancy': peakOccupancy,
        'currentOccupancy': currentOccupancy,
        'unaccounted': unaccounted,
      };
}

/// How a single claim in the situation report stood up to the evidence.
///
/// The three categories are Table 3.20's, applied at release time rather than in
/// analysis afterwards. [contradicted] claims never arrive — the backend strips
/// them — so in practice the app renders [supported] plainly and marks
/// [unsupported].
enum ClaimGrounding {
  supported,
  unsupported,
  contradicted;

  /// True when nothing in the system could confirm or deny it. Shown, but never
  /// shown as a finding.
  bool get needsMarking => this == ClaimGrounding.unsupported;

  static ClaimGrounding fromWire(String? s) => switch (s) {
        'contradicted' => ClaimGrounding.contradicted,
        'unsupported' => ClaimGrounding.unsupported,
        _ => ClaimGrounding.supported,
      };
}

/// One statement in the situation report, with its verdict.
class ReportClaim {
  const ReportClaim({
    required this.id,
    required this.label,
    required this.text,
    required this.grounding,
    this.evidence = '',
    this.why = '',
  });

  final String id;
  final String label;
  final String text;
  final ClaimGrounding grounding;

  /// What checked it — "human detector", "classifier", "zone model".
  final String evidence;
  final String why;

  factory ReportClaim.fromJson(Map<String, dynamic> j) => ReportClaim(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        text: j['text'] as String? ?? '',
        grounding: ClaimGrounding.fromWire(j['category'] as String?),
        evidence: j['evidence'] as String? ?? '',
        why: j['why'] as String? ?? '',
      );
}

/// The situation report (RO3.1), after every claim was checked against the
/// logged detection and sensor evidence.
///
/// WHAT ARRIVES HERE HAS ALREADY BEEN FILTERED. Claims the evidence contradicted
/// were withheld by the backend, which is the point of validating before release
/// rather than afterwards. What the app still has to do is honour the
/// distinction between a claim that was confirmed and one that merely could not
/// be checked — rendering those identically would undo the whole exercise.
class SituationReport {
  const SituationReport({
    this.claims = const [],
    this.narrative = '',
    this.withheldCount = 0,
    this.groundingAccuracy,
  });

  final List<ReportClaim> claims;

  /// The model's own sentence, carried as context. Never a graded finding.
  final String narrative;

  /// How many claims the evidence contradicted and the backend removed.
  final int withheldCount;
  final double? groundingAccuracy;

  bool get isEmpty => claims.isEmpty && narrative.isEmpty;
  List<ReportClaim> get shown =>
      claims.where((c) => c.grounding != ClaimGrounding.contradicted).toList();
  bool get hasUnverified => shown.any((c) => c.grounding.needsMarking);

  factory SituationReport.fromJson(Map<String, dynamic> j) {
    final g = j['grounding'] as Map<String, dynamic>? ?? const {};
    return SituationReport(
      claims: (j['claims'] as List<dynamic>? ?? const [])
          .map((e) => ReportClaim.fromJson(e as Map<String, dynamic>))
          .toList(),
      narrative: j['narrative'] as String? ?? '',
      withheldCount: _asInt(g['contradicted']),
      groundingAccuracy: g['groundingAccuracy'] == null
          ? null
          : _asDouble(g['groundingAccuracy']),
    );
  }
}

/// An active, confirmed emergency (drives the incident + resolved screens).
class Incident {
  const Incident({
    this.id = '',
    required this.zone,
    required this.event,
    required this.muster,
    this.severity = IncidentSeverity.fire,
    this.verification = Verification.confirmed,
    this.occupancy = const Occupancy(),
    this.classification,
    this.sensorSummary = '',
    this.route,
    this.checkout = const CheckoutRoll(),
    this.situationReport,
  });

  final String id;
  final Zone zone;
  final DetectionEvent event;
  final MusterRoll muster;

  /// Which alarm tier. Every field below it is optional with a default, because
  /// `MockData` builds these as `const` literals and a required field would be a
  /// compile error at every one of them.
  final IncidentSeverity severity;
  final Verification verification;
  final Occupancy occupancy;
  final FireClassification? classification;

  /// The raw reading line behind a gas event, e.g. "MQ-2 620 ppm (warn), CO 45
  /// ppm (warn)". Shown small, under the description: the sentence is a
  /// judgement, and this is the evidence a reader can check it against.
  final String sensorSummary;

  /// The generated escape route, or null when there is none — no incident, an
  /// incident from before routing existed, or generation failed. Null renders as
  /// the plan with no overlays, a path the drawing already had.
  final EvacRoute? route;

  /// Check-out progress, kept separate from [muster] on purpose — see
  /// [CheckoutRoll].
  final CheckoutRoll checkout;

  /// The validated situation report, or null when none was generated.
  final SituationReport? situationReport;

  /// True for the neutral stand-in the repository holds so `activeIncident` is
  /// never null. The dashboard needs this because the backend deliberately
  /// reports `allClear: true` *alongside* an open gas warning — nothing is
  /// burning, so the zone is not red — and a single-source check would print
  /// "All clear" over a live warning.
  bool get isPlaceholder => id.isEmpty && event.type == DetectionType.none;

  /// True when this calls for evacuation. A gas warning does not.
  bool get isAlarm => !isPlaceholder && severity.isAlarm;

  /// Whether a confidence figure means anything here. A carbon-monoxide alarm
  /// arrives with 0.0 by design, and "Confidence 0%" beside a live alarm reads
  /// as a broken screen rather than as the sensor-only detection it is.
  bool get hasMeaningfulConfidence =>
      severity == IncidentSeverity.fire && event.confidence > 0;

  factory Incident.fromJson(Map<String, dynamic> j) => Incident(
        id: j['id'] as String? ?? '',
        zone: Zone.fromJson(j['zone'] as Map<String, dynamic>),
        event: DetectionEvent.fromJson(j['event'] as Map<String, dynamic>),
        muster: MusterRoll.fromJson(j['muster'] as Map<String, dynamic>?),
        severity: IncidentSeverity.fromWire(j['severity'] as String?),
        verification: Verification.fromWire(j['verification'] as String?),
        occupancy: Occupancy.fromJson(j['occupancy'] as Map<String, dynamic>?),
        sensorSummary: j['sensorSummary'] as String? ?? '',
        route: j['route'] == null
            ? null
            : EvacRoute.fromJson(j['route'] as Map<String, dynamic>),
        checkout: CheckoutRoll.fromJson(j['checkout'] as Map<String, dynamic>?),
        situationReport: j['situationReport'] == null
            ? null
            : SituationReport.fromJson(
                j['situationReport'] as Map<String, dynamic>),
        classification: j['classification'] == null
            ? null
            : FireClassification.fromJson(
                j['classification'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'zone': zone.toJson(),
        'event': event.toJson(),
        'muster': muster.toJson(),
        'severity': severity.wire,
        'verification': verification.wire,
        'occupancy': occupancy.toJson(),
        'classification': classification?.toJson(),
        'sensorSummary': sensorSummary,
        'checkout': checkout.toJson(),
      };
}

/// One scene-AI observation logged during a past event.
class SceneNote {
  const SceneNote({
    required this.timeLabel,
    required this.text,
    required this.state,
  });

  final String timeLabel; // e.g. "19:30:04 · detected"
  final String text;
  final SceneState state;

  factory SceneNote.fromJson(Map<String, dynamic> j) => SceneNote(
        timeLabel: j['timeLabel'] as String? ?? '',
        text: j['text'] as String? ?? '',
        state: SceneState.fromWire(j['state'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'timeLabel': timeLabel,
        'text': text,
        'state': state.wire,
      };
}

/// A resolved event in the history log.
class HistoryEvent {
  const HistoryEvent({
    required this.id,
    required this.zoneName,
    required this.type,
    required this.whenLabel,
    required this.durationMin,
    required this.floor,
    required this.resolution,
    required this.peakConfidencePct,
    this.cause,
    this.sceneNotes = const [],
  });

  final String id;
  final String zoneName;
  final DetectionType type;
  final String whenLabel; // e.g. "Yesterday 19:30"
  final int durationMin;
  final String floor;
  final String? cause; // e.g. "dust", "steam"
  final Resolution resolution;
  final int peakConfidencePct;
  final List<SceneNote> sceneNotes;

  bool get hasDetail => sceneNotes.isNotEmpty;

  factory HistoryEvent.fromJson(Map<String, dynamic> j) => HistoryEvent(
        id: j['id'] as String? ?? '',
        zoneName: j['zoneName'] as String? ?? '',
        type: DetectionType.fromWire(j['type'] as String?),
        whenLabel: j['whenLabel'] as String? ?? '',
        durationMin: _asInt(j['durationMin']),
        floor: j['floor'] as String? ?? '',
        resolution: Resolution.fromWire(j['resolution'] as String?),
        peakConfidencePct: _asInt(j['peakConfidencePct']),
        cause: j['cause'] as String?,
        sceneNotes: (j['sceneNotes'] as List<dynamic>? ?? const [])
            .map((e) => SceneNote.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'zoneName': zoneName,
        'type': type.wire,
        'whenLabel': whenLabel,
        'durationMin': durationMin,
        'floor': floor,
        'resolution': resolution.wire,
        'peakConfidencePct': peakConfidencePct,
        'cause': cause,
        'sceneNotes': sceneNotes.map((n) => n.toJson()).toList(),
      };
}

/// One stamp on the incident timeline.
class ReportEvent {
  const ReportEvent({required this.at, required this.what, this.detail = ''});

  final DateTime? at;
  final String what;
  final String detail;

  factory ReportEvent.fromJson(Map<String, dynamic> j) => ReportEvent(
        at: j['at'] == null ? null : DateTime.tryParse('${j['at']}')?.toLocal(),
        what: j['what'] as String? ?? '',
        detail: j['detail'] as String? ?? '',
      );
}

/// The record of one incident, read after it is over.
///
/// Deliberately a different shape from [Incident]. A responder wants to know
/// what is burning; an investigation wants to know **when the system knew it**,
/// and the gaps between the stamps are the answer. `warningToFireS` in
/// particular is the measured notice the sensors gave before anything was
/// visible — which is the entire justification for the warning tier, and it is
/// lost the moment the incident closes unless it is read from here.
class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.zoneName,
    required this.severity,
    this.escalatedFromWarning = false,
    this.fuelLabel,
    this.guidance = '',
    this.timeline = const [],
    this.warningToFireS,
    this.fireToClassifiedS,
    this.totalS,
    this.checkout = const CheckoutRoll(),
    this.deliveryP50Ms,
    this.deliveryP95Ms,
    this.routeExitName,
    this.routeLengthM,
    this.routeLatencyMs,
    this.caveats = const [],
  });

  final String id;
  final String zoneName;
  final IncidentSeverity severity;
  final bool escalatedFromWarning;
  final String? fuelLabel;
  final String guidance;
  final List<ReportEvent> timeline;

  /// Seconds of notice the sensors gave before a flame was visible.
  final int? warningToFireS;
  final int? fireToClassifiedS;
  final int? totalS;

  final CheckoutRoll checkout;
  final double? deliveryP50Ms;
  final double? deliveryP95Ms;
  final String? routeExitName;
  final double? routeLengthM;
  final double? routeLatencyMs;
  final List<String> caveats;

  static int? _optInt(dynamic v) => v == null ? null : _asInt(v);
  static double? _optDouble(dynamic v) => v == null ? null : _asDouble(v);

  factory IncidentReport.fromJson(Map<String, dynamic> j) {
    final durations = j['durations'] as Map<String, dynamic>? ?? const {};
    final delivery = j['delivery'] as Map<String, dynamic>? ?? const {};
    final classification = j['classification'] as Map<String, dynamic>?;
    final route = j['route'] as Map<String, dynamic>?;
    final zone = j['zone'] as Map<String, dynamic>? ?? const {};
    return IncidentReport(
      id: j['id'] as String? ?? '',
      zoneName: zone['name'] as String? ?? '',
      severity: IncidentSeverity.fromWire(j['severity'] as String?),
      escalatedFromWarning: j['escalatedFromWarning'] as bool? ?? false,
      fuelLabel: classification?['label'] as String?,
      guidance: classification?['guidance'] as String? ?? '',
      timeline: (j['timeline'] as List<dynamic>? ?? const [])
          .map((e) => ReportEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      warningToFireS: _optInt(durations['warningToFireS']),
      fireToClassifiedS: _optInt(durations['fireToClassifiedS']),
      totalS: _optInt(durations['totalS']),
      checkout: CheckoutRoll.fromJson(j['checkout'] as Map<String, dynamic>?),
      deliveryP50Ms: _optDouble(delivery['p50Ms']),
      deliveryP95Ms: _optDouble(delivery['p95Ms']),
      routeExitName: route?['exitName'] as String?,
      routeLengthM: _optDouble(route?['lengthM']),
      routeLatencyMs: _optDouble(j['routeLatencyMs']),
      caveats: (j['caveats'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
    );
  }
}

/// A dashboard system-health tile.
class HealthStat {
  const HealthStat({
    required this.label,
    required this.value,
    this.ok = true,
  });

  final String label;
  final String value;
  final bool ok;

  factory HealthStat.fromJson(Map<String, dynamic> j) => HealthStat(
        label: j['label'] as String? ?? '',
        value: j['value'] as String? ?? '',
        ok: j['ok'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'label': label, 'value': value, 'ok': ok};
}
